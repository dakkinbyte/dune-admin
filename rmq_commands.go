package main

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"strings"
	"sync"
	"time"
)

// randomChatGUID returns a 32-char uppercase hex string for FChatMessageData.m_Id.
// Real game GUIDs are random across all bytes — formatting a UnixNano timestamp
// as hex produces leading zeros that text-router's pre-filter rejects.
func randomChatGUID() string {
	b := make([]byte, 16)
	if _, err := rand.Read(b); err != nil {
		// Fallback: timestamp-based but still distinct, in case rand fails.
		return strings.ToUpper(fmt.Sprintf("%032x", time.Now().UnixNano()))
	}
	return strings.ToUpper(hex.EncodeToString(b))
}

// serverCmdAuthToken is the static AuthToken the game server validates on
// incoming server command envelopes. Extracted from send-dune-broadcast.
const serverCmdAuthToken = "Nu6VmPWUMvdPMeB7qErr"

// chatHostIDCache holds the captured HostId for publishCourierMessage's
// AMQP user_id field. text-router's redirect filter only accepts messages
// where user_id matches a known game-host identity (it silently drops
// publishes with user_id="fls"). The HostId comes from the game-server JWT
// in process args and is stable for the lifetime of the game-server
// instance. We refresh on miss but otherwise cache it.
var (
	chatHostIDCacheMu  sync.RWMutex
	chatHostIDCacheVal string
)

func cachedChatHostID() string {
	chatHostIDCacheMu.RLock()
	cached := chatHostIDCacheVal
	chatHostIDCacheMu.RUnlock()
	if cached != "" {
		return cached
	}
	if globalControl == nil || globalExecutor == nil {
		return "fls"
	}
	// Real chat publishes use a service-grain user_id of the form
	//   sg.sh-{host-lowercase}-onhuqk.{server-grain-id}.game
	// where server-grain-id is one of the partition-server identifiers
	// (visible in `queue.server.<id>` queue names). We grab the first
	// server grain we find — text-router maps grain → redirect-exchange,
	// and any server's grain works for admin-side publishes.
	host, _, err := globalControl.CaptureJWT(context.Background(), globalExecutor)
	if err != nil || host == "" {
		return "fls"
	}
	serverGrain := lookupAnyServerGrain()
	if serverGrain == "" {
		// Fall back to bare host id — text-router won't redirect but the
		// publish still succeeds at the broker layer.
		chatHostIDCacheMu.Lock()
		chatHostIDCacheVal = host
		chatHostIDCacheMu.Unlock()
		return host
	}
	full := fmt.Sprintf("sg.sh-%s-onhuqk.%s.game", strings.ToLower(host), serverGrain)
	chatHostIDCacheMu.Lock()
	chatHostIDCacheVal = full
	chatHostIDCacheMu.Unlock()
	return full
}

// lookupAnyServerGrain returns one of the AMP-managed server-grain IDs by
// listing the `queue.server.<id>` queues on the game broker and stripping the
// prefix. Any one works for admin-side chat publishes.
func lookupAnyServerGrain() string {
	if globalControl == nil || globalExecutor == nil {
		return ""
	}
	// rabbitmqctl list_queues name | grep ^queue.server.
	amp, ok := globalControl.(*ampControl)
	if !ok {
		return ""
	}
	cmd := amp.buildRabbitmqctl("mq-game", "list_queues name")
	out, err := globalExecutor.Exec(cmd + " 2>/dev/null | grep '^queue.server.' | head -1")
	if err != nil || out == "" {
		return ""
	}
	line := strings.TrimSpace(strings.Split(out, "\n")[0])
	return strings.TrimPrefix(line, "queue.server.")
}

// ── core publish ──────────────────────────────────────────────────────────────

// publishServerCommand sends a server command to the game via rabbitmqctl eval
// executed inside the mq-game broker pod. This mirrors send-dune-broadcast:
// the Erlang P_basic tuple sets user_id="fls", which AMQP connections cannot
// do (the broker validates UserId against the authenticated username).
func publishServerCommand(fields map[string]any) error {
	inner, err := json.Marshal(fields)
	if err != nil {
		return fmt.Errorf("marshal server command: %w", err)
	}

	outer, err := json.Marshal(map[string]any{
		"Version":        2,
		"AuthToken":      serverCmdAuthToken,
		"MessageContent": string(inner),
	})
	if err != nil {
		return fmt.Errorf("marshal envelope: %w", err)
	}

	// Pass the envelope as base64 to avoid any Erlang string-escaping issues.
	outerB64 := base64.StdEncoding.EncodeToString(outer)
	msgID := fmt.Sprintf("dune-admin-cmd-%d", time.Now().UnixMilli())

	erlang := fmt.Sprintf(
		`Outer = base64:decode(<<"%s">>),`+
			`XName = rabbit_misc:r(<<"/">>, exchange, <<"heartbeats">>),`+
			`X = rabbit_exchange:lookup_or_die(XName),`+
			`MsgId = <<"%s">>,`+
			`P = {list_to_atom("P_basic"), <<"Content">>, undefined, [], undefined,`+
			` undefined, undefined, undefined, undefined, MsgId, undefined,`+
			` undefined, <<"fls">>, <<"fls_backend">>, undefined},`+
			`Content = rabbit_basic:build_content(P, Outer),`+
			`{ok, Msg} = rabbit_basic:message(XName, <<"notifications">>, Content),`+
			`rabbit_queue_type:publish_at_most_once(X, Msg).`,
		outerB64, msgID)

	if globalControl == nil || globalExecutor == nil {
		return fmt.Errorf("control plane not connected")
	}

	_, err = globalControl.EvalOnGameBroker(context.Background(), globalExecutor, erlang)
	if err != nil {
		return fmt.Errorf("publish server command: %w", err)
	}
	return nil
}

// ── courier (chat) publish ────────────────────────────────────────────────────

// channelExchange maps an m_ChannelType value to the chat output exchange the
// text-router should redirect to. Used as the RedirectExchange AMQP header.
func channelExchange(channel string) string {
	switch channel {
	case "Whispers":
		return "chat.whispers"
	case "Proximity":
		return "chat.proximity"
	case "Map":
		return "chat.map"
	case "Party":
		return "" // party.{id} — caller must override
	case "Faction":
		return "" // faction.{id} — caller must override
	case "Guild":
		return "" // guild.{id} — caller must override
	}
	return ""
}

// publishCourierMessage publishes a chat / courier message to the game broker.
// Unlike publishServerCommand (which goes to exchange=heartbeats,
// routingKey=notifications via the ServerCommand AuthToken-protected envelope),
// courier messages are routed by exchange + routingKey directly — exchange is
// chat-channel-specific (chat.whispers, chat.faction.{id}, ...) and routing key
// varies by channel (target FLS for whispers, "" for faction broadcasts, etc.).
//
// EXPERIMENTAL — Adain's chat-and-courier.md documents the wire format from
// IDA/DWARF analysis but explicitly notes "live external publish recipe still
// not pinned." This is the first attempt at sending one of these as an external
// operator. If the game ignores the message or the broker rejects it, see
// chat-and-courier.md and iterate the basic_properties or body shape.
//
// body should be the JSON-serialized FCourierMessageContent — caller's
// responsibility. typeStr is the AMQP basic_properties `type` value, set to
// "12" for text_chat per the FNotificationsSystemMessage type-byte mapping.
func publishCourierMessage(exchange, routingKey string, body []byte, typeStr, redirectExchange string) error {
	bodyB64 := base64.StdEncoding.EncodeToString(body)
	msgID := fmt.Sprintf("dune-admin-chat-%d", time.Now().UnixMilli())

	userID := cachedChatHostID()

	// AMQP basic_properties P_basic record order:
	//   content_type, content_encoding, headers, delivery_mode, priority,
	//   correlation_id, reply_to, expiration, message_id, timestamp, type,
	//   user_id, app_id, cluster_id
	// Best-known wire format as of 2026-05-27 (partial — does NOT yet land in
	// player chat UI). Status notes:
	//   ✓ broker accepts the publish
	//   ✓ text-router consumes from chat.intercept and logs "received message"
	//   ✗ text-router's GetMessageRedirectExchange returns "" so "Starting
	//     filtering ... for exchange ___" has empty exchange — no redirect
	//
	// Tried and ruled out: type values ("12", "text_chat", channel name);
	// user_id (fls, bare host id, full grain id); 9 different header names
	// for RedirectExchange; reply_to as the destination. None caused the
	// redirect-exchange lookup to return a non-empty value.
	//
	// Next investigation: AMQP-snooper to capture real-message basic_properties
	// (esp. binary headers) — those aren't visible in text-router's text log.
	erlang := fmt.Sprintf(
		`Body = base64:decode(<<"%s">>),`+
			`XName = rabbit_misc:r(<<"/">>, exchange, <<"%s">>),`+
			`X = rabbit_exchange:lookup_or_die(XName),`+
			`MsgId = <<"%s">>,`+
			`Hdrs = [{<<"RedirectExchange">>, longstr, <<"%s">>}],`+
			`P = {list_to_atom("P_basic"), <<"Content">>, undefined, Hdrs, undefined,`+
			` undefined, undefined, undefined, undefined, MsgId, undefined,`+
			` <<"%s">>, <<"%s">>, <<"fls_backend">>, undefined},`+
			`Content = rabbit_basic:build_content(P, Body),`+
			`{ok, Msg} = rabbit_basic:message(XName, <<"%s">>, Content),`+
			`rabbit_queue_type:publish_at_most_once(X, Msg).`,
		bodyB64, exchange, msgID, redirectExchange, typeStr, userID, routingKey)

	if globalControl == nil || globalExecutor == nil {
		return fmt.Errorf("control plane not connected")
	}
	out, err := globalControl.EvalOnGameBroker(context.Background(), globalExecutor, erlang)
	if err != nil {
		return fmt.Errorf("publish courier message: %w (output: %s)", err, out)
	}
	return nil
}

// rmqSendChat sends a chat message into one of the courier channels. The wire
// format is captured from a real in-game chat message (text-router.log on the
// test VM, 2026-05-27): the inner FChatMessageData JSON keeps its m_-prefixed
// field names, m_ChannelType uses bare enum values ("Whispers", "Proximity",
// "Faction", "Guild", "Map"), and the outer Type discriminator is just
// "TextChat" not "ECourierMessageType::TextChat".
//
// Routing differs per channel — caller supplies exchange + routingKey directly.
//
//	Whisper:   exchange="chat.whispers",    routingKey=<target FLS id>
//	Proximity: exchange="chat.proximity",   routingKey=<sender FLS id>  (game server filters by location)
//	Map:       exchange="chat.map",         routingKey="<map>.<dimension>"
//	Faction:   exchange="chat.faction.<n>", routingKey="" (fanout)
//	Guild:     exchange="chat.guild.<id>",  routingKey="" (fanout)
//
// senderFlsID is the m_FuncomIdFrom value. For admin use it can be any valid
// player FLS id (impersonation) or a synthetic admin id. spoofedDisplayName
// overrides the visible author — if non-empty, m_bUseSpoofedUserName is true
// and the name shows in the chat UI instead of senderFlsID's character name.
// userNameTo is only meaningful for Whispers (target character name).
func rmqSendChat(exchange, routingKey, channelType, senderFlsID, userNameTo, spoofedDisplayName, message string) error {
	// 32-char uppercase hex GUID (matches the format in real captures).
	// Must be random across all bytes — text-router rejects IDs with leading
	// zero bytes (the timestamp-as-hex pattern).
	msgID := randomChatGUID()

	emptyFText := map[string]any{
		"m_TableId":          "",
		"m_Key":              "",
		"m_UnlocalizedName":  "",
	}
	spoofedAuthor := emptyFText
	if spoofedDisplayName != "" {
		spoofedAuthor = map[string]any{
			"m_TableId":         "",
			"m_Key":             "",
			"m_UnlocalizedName": spoofedDisplayName,
		}
	}

	chatMsg := map[string]any{
		"m_Id":                  msgID,
		"m_ChannelType":         channelType,
		"m_bUseSpoofedUserName": spoofedDisplayName != "",
		"m_SpoofedUserNameFrom": spoofedAuthor,
		"m_FuncomIdFrom":        senderFlsID,
		"m_UserNameTo":          userNameTo,
		"m_Message": map[string]any{
			"m_UnlocalizedMessage": message,
			"m_LocalizedMessage": map[string]any{
				"m_TableId":   "",
				"m_Key":       "",
				"m_FormatArgs": []any{},
			},
		},
		"m_Timestamp":      time.Now().UTC().Format("2006.01.02-15.04.05"),
		"m_OriginLocation": map[string]any{"X": 0.0, "Y": 0.0, "Z": 0.0},
		"m_HasSeenMessage": false,
	}
	chatJSON, err := json.Marshal(chatMsg)
	if err != nil {
		return fmt.Errorf("marshal chat message: %w", err)
	}

	envelope := map[string]any{
		"Content": string(chatJSON),
		"Type":    "TextChat",
	}
	envelopeJSON, err := json.Marshal(envelope)
	if err != nil {
		return fmt.Errorf("marshal courier envelope: %w", err)
	}

	// AMQP `type` basic property = the channel name. Iteration history:
	//   "12"        → NullReferenceException in GetMessageRedirectExchange
	//   "text_chat" → past NRE but redirect exchange returns empty string
	//   <channel>   → trying this — text-router may use type as the lookup key
	return publishCourierMessage(exchange, routingKey, envelopeJSON, channelType, channelExchange(channelType))
}

// rmqSendWhisper is a convenience wrapper for the Whispers channel.
//
// IMPORTANT — Adain's docs imply direct publish to chat.whispers should land
// at the player's queue, but live testing shows the player's GAME CLIENT
// rejects messages that didn't transit the text-router. Publishing to
// chat.intercept (the topic exchange the text-router consumes from) lets the
// text-router pick the message up, filter, and re-publish to the appropriate
// output exchange (chat.whispers / chat.proximity / chat.map / etc.) based on
// the m_ChannelType in the body. text-router logs every redirect, so failed
// delivery shows up in /AMP/duneawakening/logs/text-router.log immediately.
//
// Routing key on chat.intercept: the captured "received message from <host>
// to <target>" log line suggests text-router only inspects the body (no
// routing-key parsing), so any non-empty routing key works. We use the
// target FLS so capture/replay tooling can still filter by target.
func rmqSendWhisper(targetFlsID, targetName, senderFlsID, spoofedDisplayName, message string) error {
	return rmqSendChat("chat.intercept", targetFlsID, "Whispers", senderFlsID, targetName, spoofedDisplayName, message)
}

// ── typed wrappers ────────────────────────────────────────────────────────────

func rmqAddItemToInventory(flsID, itemName string, qty int, durability float64) error {
	return publishServerCommand(map[string]any{
		"ServerCommand": "AddItemToInventory",
		"PlayerId":      flsID,
		"ItemName":      itemName,
		"Quantity":      qty,
		"Durability":    durability,
	})
}

func rmqKickPlayer(flsID string) error {
	return publishServerCommand(map[string]any{
		"ServerCommand": "KickPlayer",
		"PlayerId":      flsID,
	})
}

func rmqUpdateAllWaterFillables(flsID string, waterAmount int) error {
	return publishServerCommand(map[string]any{
		"ServerCommand": "UpdateAllWaterFillables",
		"PlayerId":      flsID,
		"WaterAmount":   waterAmount,
	})
}

func rmqAwardXP(flsID, category string, experience int) error {
	return publishServerCommand(map[string]any{
		"ServerCommand": "AwardXP",
		"PlayerId":      flsID,
		"Category":      category,
		"Experience":    experience,
	})
}

func rmqSkillsSetUnspentSkillPoints(flsID string, skillPoints int) error {
	return publishServerCommand(map[string]any{
		"ServerCommand": "SkillsSetUnspentSkillPoints",
		"PlayerId":      flsID,
		"SkillPoints":   skillPoints,
	})
}

type localizedText struct {
	Key   string `json:"Key"`
	Title string `json:"Title"`
	Body  string `json:"Body"`
}

func rmqServiceBroadcastGeneric(durationSec int, texts []localizedText) error {
	return publishServerCommand(map[string]any{
		"ServerCommand": "ServiceBroadcast",
		"BroadcastType": "Generic",
		"BroadcastPayload": map[string]any{
			"BroadcastDuration": durationSec,
			"LocalizedText":     texts,
		},
	})
}

func rmqServiceBroadcastShutdown(shutdownType string, timestamp int64, frequency, duration int, shouldCancel bool) error {
	payload := map[string]any{
		"ShutdownType":      shutdownType,
		"ShouldCancel":      shouldCancel,
		"ShutdownTimestamp": timestamp,
		"BroadcastFrequency": frequency,
		"ShutdownDuration":  duration,
		"DateTimestamp":     timestamp,
	}
	return publishServerCommand(map[string]any{
		"ServerCommand":    "ServiceBroadcast",
		"BroadcastType":    "ServerShutdown",
		"BroadcastPayload": payload,
	})
}

func rmqCheatScript(flsID, scriptName string) error {
	return publishServerCommand(map[string]any{
		"ServerCommand": "CheatScript",
		"PlayerId":      flsID,
		"ScriptName":    scriptName,
	})
}

func rmqCleanPlayerInventory(flsID string) error {
	return publishServerCommand(map[string]any{
		"ServerCommand": "CleanPlayerInventory",
		"PlayerId":      flsID,
	})
}

func rmqResetProgression(flsID string) error {
	return publishServerCommand(map[string]any{
		"ServerCommand": "ResetProgression",
		"PlayerId":      flsID,
	})
}

func rmqTeleportTo(flsID string, x, y, z float64) error {
	return publishServerCommand(map[string]any{
		"ServerCommand": "TeleportTo",
		"PlayerId":      flsID,
		"X":             x,
		"Y":             y,
		"Z":             z,
	})
}

// rmqTeleportToExact uses the engine's exact-location teleport path (no snap
// to nearest safe ground). Used for teleport-to-player, where the admin wants
// the source player to land precisely on top of the target rather than
// somewhere "safe" nearby. Per Adain's protocol docs.
func rmqTeleportToExact(flsID string, x, y, z float64) error {
	return publishServerCommand(map[string]any{
		"ServerCommand": "TeleportToExact",
		"PlayerId":      flsID,
		"X":             x,
		"Y":             y,
		"Z":             z,
	})
}

func rmqSkillsSetModuleLevel(flsID, module string, level int) error {
	return publishServerCommand(map[string]any{
		"ServerCommand": "SkillsSetModuleLevel",
		"PlayerId":      flsID,
		"Module":        module,
		"Level":         level,
	})
}

func rmqSpawnVehicleAt(flsID, className string, x, y, z, rotation float64, templateName string, persistent bool, faction string) error {
	fields := map[string]any{
		"ServerCommand": "SpawnVehicleAt",
		"PlayerId":      flsID,
		"ClassName":     className,
		"X":             x,
		"Y":             y,
		"Z":             z,
	}
	if rotation != 0 {
		fields["Rotation"] = rotation
	}
	if templateName != "" {
		fields["TemplateName"] = templateName
	}
	persistVal := 0.0
	if persistent {
		persistVal = 1.0
	}
	fields["Persistent"] = persistVal
	if faction != "" {
		fields["Faction"] = faction
	}
	return publishServerCommand(fields)
}


// ── player ID resolution ──────────────────────────────────────────────────────

// flsIDFromActorID resolves the accounts."user" hex Funcom UUID for an actor
// (player pawn). This is the PlayerId format expected by RMQ server commands.
func flsIDFromActorID(ctx context.Context, actorID int64) (string, error) {
	if globalDB == nil {
		return "", fmt.Errorf("not connected")
	}
	var flsID string
	err := globalDB.QueryRow(ctx, `
		SELECT ac."user"
		FROM dune.accounts ac
		JOIN dune.actors a ON a.owner_account_id = ac.id
		WHERE a.id = $1`, actorID).Scan(&flsID)
	if err != nil {
		return "", fmt.Errorf("resolve fls id for actor %d: %w", actorID, err)
	}
	return flsID, nil
}


// containerOwnerInfo holds the resolved owner details for a storage container.
type containerOwnerInfo struct {
	FlsID     string // accounts."user" hex Funcom UUID — used as PlayerId in RMQ commands
	AccountID int64  // accounts.id — used to check online status
}

// ownerFromContainerID resolves the FLS hex ID and account ID for the player
// who owns a storage container actor. Chain: placeables.owner_entity_id →
// actor_fgl_entities → actors.owner_account_id → accounts.
func ownerFromContainerID(ctx context.Context, containerID int64) (containerOwnerInfo, error) {
	if globalDB == nil {
		return containerOwnerInfo{}, fmt.Errorf("not connected")
	}
	var info containerOwnerInfo
	err := globalDB.QueryRow(ctx, `
		SELECT ac."user", ac.id
		FROM dune.placeables p
		JOIN dune.actor_fgl_entities afe  ON afe.entity_id = p.owner_entity_id
		JOIN dune.permission_actor_rank par ON par.permission_actor_id = afe.actor_id
		JOIN dune.actors player_a           ON player_a.id = par.player_id
		JOIN dune.accounts ac               ON ac.id = player_a.owner_account_id
		WHERE p.id = $1
		LIMIT 1`, containerID).Scan(&info.FlsID, &info.AccountID)
	if err != nil {
		return containerOwnerInfo{}, fmt.Errorf("resolve container owner %d: %w", containerID, err)
	}
	return info, nil
}

// isAccountOnline returns true if the account currently has a non-Offline
// player_state row. Uses account_id directly, suitable for storage container
// owner checks where the pawn actor ID is not readily available.
func isAccountOnline(ctx context.Context, accountID int64) bool {
	if globalDB == nil {
		return false
	}
	var status string
	err := globalDB.QueryRow(ctx, `
		SELECT COALESCE(online_status::text, 'Offline')
		FROM dune.player_state
		WHERE account_id = $1
		LIMIT 1`, accountID).Scan(&status)
	if err != nil {
		return false
	}
	return status != "Offline"
}

// playerIDDebug returns all relevant player ID forms for a given actor ID.
// Used by the debug endpoint to verify which ID format the game server expects.
func playerIDDebug(ctx context.Context, actorID int64) (map[string]string, error) {
	if globalDB == nil {
		return nil, fmt.Errorf("not connected")
	}
	var displayName, hexID string
	err := globalDB.QueryRow(ctx, `
		SELECT convert_from(e.encrypted_funcom_id, 'UTF8'), COALESCE(ac."user", '')
		FROM dune.encrypted_accounts e
		JOIN dune.actors a ON a.owner_account_id = e.id
		LEFT JOIN dune.accounts ac ON ac.id = e.id
		WHERE a.id = $1`, actorID).Scan(&displayName, &hexID)
	if err != nil {
		return nil, fmt.Errorf("lookup actor %d: %w", actorID, err)
	}
	return map[string]string{
		"display_name": displayName,
		"hex_id":       hexID,
	}, nil
}

// isHexIDOnline returns true if the player identified by their hex Funcom UUID
// (accounts."user") currently has a non-Offline online_status.
func isHexIDOnline(ctx context.Context, hexID string) bool {
	if globalDB == nil {
		return false
	}
	var status string
	err := globalDB.QueryRow(ctx, `
		SELECT COALESCE(ps.online_status::text, 'Offline')
		FROM dune.accounts ac
		JOIN dune.player_state ps ON ps.account_id = ac.id
		WHERE ac."user" = $1
		LIMIT 1`, hexID).Scan(&status)
	if err != nil {
		return false
	}
	return status != "Offline"
}

// displayNameFromHexID resolves the encrypted_funcom_id display name
// (e.g. "Icehunter#55381") from the hex Funcom UUID in accounts."user".
// Used by DB paths that identify players by display name.
func displayNameFromHexID(ctx context.Context, hexID string) (string, error) {
	if globalDB == nil {
		return "", fmt.Errorf("not connected")
	}
	var name string
	err := globalDB.QueryRow(ctx, `
		SELECT convert_from(e.encrypted_funcom_id, 'UTF8')
		FROM dune.accounts ac
		JOIN dune.encrypted_accounts e ON e.id = ac.id
		WHERE ac."user" = $1`, hexID).Scan(&name)
	if err != nil {
		return "", fmt.Errorf("resolve display name for %s: %w", hexID, err)
	}
	return name, nil
}
