package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"time"
)

// All handlers in this file publish RabbitMQ server commands.
// They are fire-and-forget — the game server applies the command and logs the
// result. The HTTP response indicates whether the command was sent, not whether
// the game server executed it successfully.

// @Summary Send kick command via RabbitMQ
// @Tags players
// @Accept json
// @Produce json
// @Param body body object true "Player FLS ID"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/v1/players/kick [post]
// POST /api/v1/players/kick
func handleRMQKickPlayer(w http.ResponseWriter, r *http.Request) {
	var req struct {
		FlsID string `json:"fls_id"`
	}
	if err := decode(r, &req); err != nil {
		jsonErr(w, err, 400)
		return
	}
	if req.FlsID == "" {
		jsonErr(w, fmt.Errorf("fls_id required"), 400)
		return
	}
	if err := rmqKickPlayer(req.FlsID); err != nil {
		jsonErr(w, err, 500)
		return
	}
	jsonOK(w, map[string]string{"ok": fmt.Sprintf("kick command sent for %s", req.FlsID)})
}

// @Summary Send fill-water command via RabbitMQ
// @Tags players
// @Accept json
// @Produce json
// @Param body body object true "Player FLS ID and optional water amount"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/v1/players/fill-water [post]
// POST /api/v1/players/fill-water
func handleRMQFillWater(w http.ResponseWriter, r *http.Request) {
	var req struct {
		FlsID       string `json:"fls_id"`
		WaterAmount int    `json:"water_amount"`
	}
	if err := decode(r, &req); err != nil {
		jsonErr(w, err, 400)
		return
	}
	if req.FlsID == "" {
		jsonErr(w, fmt.Errorf("fls_id required"), 400)
		return
	}
	if req.WaterAmount <= 0 {
		req.WaterAmount = 1000000
	}
	if err := rmqUpdateAllWaterFillables(req.FlsID, req.WaterAmount); err != nil {
		jsonErr(w, err, 500)
		return
	}
	jsonOK(w, map[string]string{"ok": fmt.Sprintf("fill water command sent for %s", req.FlsID)})
}

// @Summary Send set-skill-points command via RabbitMQ
// @Tags players
// @Accept json
// @Produce json
// @Param body body object true "Player FLS ID and skill points value"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/v1/players/set-skill-points [post]
// POST /api/v1/players/set-skill-points
func handleRMQSetSkillPoints(w http.ResponseWriter, r *http.Request) {
	var req struct {
		FlsID       string `json:"fls_id"`
		SkillPoints int    `json:"skill_points"`
	}
	if err := decode(r, &req); err != nil {
		jsonErr(w, err, 400)
		return
	}
	if req.FlsID == "" {
		jsonErr(w, fmt.Errorf("fls_id required"), 400)
		return
	}
	if err := rmqSkillsSetUnspentSkillPoints(req.FlsID, req.SkillPoints); err != nil {
		jsonErr(w, err, 500)
		return
	}
	jsonOK(w, map[string]string{"ok": fmt.Sprintf("set skill points %d sent for %s", req.SkillPoints, req.FlsID)})
}

// @Summary Send server-wide broadcast message via RabbitMQ
// @Tags broadcast
// @Accept json
// @Produce json
// @Param body body object true "Localized texts and optional duration in seconds"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/v1/broadcast [post]
// POST /api/v1/broadcast
func handleRMQBroadcast(w http.ResponseWriter, r *http.Request) {
	var req struct {
		DurationSec int             `json:"duration_sec"`
		Texts       []localizedText `json:"texts"`
	}
	if err := decode(r, &req); err != nil {
		jsonErr(w, err, 400)
		return
	}
	if len(req.Texts) == 0 {
		jsonErr(w, fmt.Errorf("texts required"), 400)
		return
	}
	if req.DurationSec <= 0 {
		req.DurationSec = 30
	}
	if err := rmqServiceBroadcastGeneric(req.DurationSec, req.Texts); err != nil {
		jsonErr(w, err, 500)
		return
	}
	jsonOK(w, map[string]string{"ok": "broadcast sent"})
}

// @Summary Send shutdown broadcast command via RabbitMQ
// @Tags broadcast
// @Accept json
// @Produce json
// @Param body body object true "Shutdown type, delay, frequency, duration, and cancel flag"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/v1/broadcast/shutdown [post]
// POST /api/v1/broadcast/shutdown
func handleRMQBroadcastShutdown(w http.ResponseWriter, r *http.Request) {
	var req struct {
		ShutdownType string `json:"shutdown_type"` // "Restart", "Maintenance", or "Update"
		DelayMinutes int    `json:"delay_minutes"`
		Frequency    int    `json:"frequency"`
		Duration     int    `json:"duration"`
		Cancel       bool   `json:"cancel"`
	}
	if err := decode(r, &req); err != nil {
		jsonErr(w, err, 400)
		return
	}
	if req.ShutdownType == "" {
		req.ShutdownType = "Restart"
	}
	ts := time.Now().Add(time.Duration(req.DelayMinutes) * time.Minute).Unix()
	if err := rmqServiceBroadcastShutdown(req.ShutdownType, ts, req.Frequency, req.Duration, req.Cancel); err != nil {
		jsonErr(w, err, 500)
		return
	}
	action := "shutdown broadcast sent"
	if req.Cancel {
		action = "shutdown broadcast cancelled"
	}
	jsonOK(w, map[string]string{"ok": action})
}

// @Summary Send cheat script command via RabbitMQ
// @Tags players
// @Accept json
// @Produce json
// @Param body body object true "Player FLS ID and script name"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/v1/players/cheat-script [post]
// POST /api/v1/players/cheat-script
func handleRMQCheatScript(w http.ResponseWriter, r *http.Request) {
	var req struct {
		FlsID      string `json:"fls_id"`
		ScriptName string `json:"script_name"`
	}
	if err := decode(r, &req); err != nil {
		jsonErr(w, err, 400)
		return
	}
	if req.FlsID == "" || req.ScriptName == "" {
		jsonErr(w, fmt.Errorf("fls_id and script_name required"), 400)
		return
	}
	if err := rmqCheatScript(req.FlsID, req.ScriptName); err != nil {
		jsonErr(w, err, 500)
		return
	}
	jsonOK(w, map[string]string{"ok": fmt.Sprintf("cheat script %q sent for %s", req.ScriptName, req.FlsID)})
}

// @Summary Send give-item command via RabbitMQ to an online player
// @Tags players
// @Accept json
// @Produce json
// @Param body body object true "Actor ID, item template, quantity, and durability"
// @Success 200 {object} map[string]any
// @Failure 400 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/v1/players/give-item-live [post]
// POST /api/v1/players/give-item-live
// Give item to an ONLINE player via RMQ. Pre-checks weight/slot limits via DB.
// Accepts actor_id (player pawn ID), resolves to FLS ID automatically.
func handleRMQGiveItem(w http.ResponseWriter, r *http.Request) {
	var req struct {
		PlayerID   int64   `json:"player_id"` // actor (pawn) ID
		Template   string  `json:"template"`
		Qty        int     `json:"qty"`
		Durability float64 `json:"durability"`
	}
	if err := decode(r, &req); err != nil {
		jsonErr(w, err, 400)
		return
	}
	if req.PlayerID == 0 || req.Template == "" {
		jsonErr(w, fmt.Errorf("player_id and template required"), 400)
		return
	}
	if req.Qty <= 0 {
		req.Qty = 1
	}
	if req.Durability <= 0 {
		req.Durability = 1.0
	}

	ctx := context.Background()

	// Check weight/slot capacity before sending to avoid bypassing limits.
	if err := checkInventoryCapacity(ctx, req.PlayerID, req.Template, int64(req.Qty)); err != nil {
		jsonErr(w, err, 400)
		return
	}

	flsID, err := flsIDFromActorID(ctx, req.PlayerID)
	if err != nil {
		jsonErr(w, fmt.Errorf("resolve player: %w", err), 404)
		return
	}

	if err := rmqAddItemToInventory(flsID, req.Template, req.Qty, req.Durability); err != nil {
		jsonErr(w, err, 500)
		return
	}
	jsonOK(w, map[string]any{
		"ok":   fmt.Sprintf("sent %d × %s to online player %d via server command", req.Qty, req.Template, req.PlayerID),
		"path": "rmq",
	})
}

// @Summary Send clean-inventory command via RabbitMQ
// @Tags players
// @Accept json
// @Produce json
// @Param body body object true "Player FLS ID"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/v1/players/clean-inventory [post]
// POST /api/v1/players/clean-inventory
func handleRMQCleanInventory(w http.ResponseWriter, r *http.Request) {
	var req struct {
		FlsID string `json:"fls_id"`
	}
	if err := decode(r, &req); err != nil {
		jsonErr(w, err, 400)
		return
	}
	if req.FlsID == "" {
		jsonErr(w, fmt.Errorf("fls_id required"), 400)
		return
	}
	if err := rmqCleanPlayerInventory(req.FlsID); err != nil {
		jsonErr(w, err, 500)
		return
	}
	jsonOK(w, map[string]string{"ok": fmt.Sprintf("clean inventory command sent for %s", req.FlsID)})
}

// @Summary Send reset-progression command via RabbitMQ
// @Tags players
// @Accept json
// @Produce json
// @Param body body object true "Player FLS ID"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/v1/players/reset-progression [post]
// POST /api/v1/players/reset-progression
func handleRMQResetProgression(w http.ResponseWriter, r *http.Request) {
	var req struct {
		FlsID string `json:"fls_id"`
	}
	if err := decode(r, &req); err != nil {
		jsonErr(w, err, 400)
		return
	}
	if req.FlsID == "" {
		jsonErr(w, fmt.Errorf("fls_id required"), 400)
		return
	}
	if err := rmqResetProgression(req.FlsID); err != nil {
		jsonErr(w, err, 500)
		return
	}
	jsonOK(w, map[string]string{"ok": fmt.Sprintf("reset progression command sent for %s", req.FlsID)})
}

// @Summary Send set-skill-module command via RabbitMQ
// @Tags players
// @Accept json
// @Produce json
// @Param body body object true "Player FLS ID, module name, and level"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/v1/players/set-skill-module [post]
// POST /api/v1/players/set-skill-module
func handleRMQSetSkillModule(w http.ResponseWriter, r *http.Request) {
	var req struct {
		FlsID  string `json:"fls_id"`
		Module string `json:"module"`
		Level  int    `json:"level"`
	}
	if err := decode(r, &req); err != nil {
		jsonErr(w, err, 400)
		return
	}
	if req.FlsID == "" || req.Module == "" {
		jsonErr(w, fmt.Errorf("fls_id and module required"), 400)
		return
	}
	if err := rmqSkillsSetModuleLevel(req.FlsID, req.Module, req.Level); err != nil {
		jsonErr(w, err, 500)
		return
	}
	jsonOK(w, map[string]string{"ok": fmt.Sprintf("set module %s level %d sent for %s", req.Module, req.Level, req.FlsID)})
}

// @Summary Send vehicle spawn command via RabbitMQ
// @Tags vehicles
// @Accept json
// @Produce json
// @Param body body object true "FLS ID, class name, coordinates, rotation, template, persistence, and faction"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/v1/vehicles/spawn [post]
// POST /api/v1/vehicles/spawn
func handleRMQSpawnVehicle(w http.ResponseWriter, r *http.Request) {
	var req struct {
		FlsID        string  `json:"fls_id"`
		ClassName    string  `json:"class_name"`
		X            float64 `json:"x"`
		Y            float64 `json:"y"`
		Z            float64 `json:"z"`
		Rotation     float64 `json:"rotation"`
		TemplateName string  `json:"template_name"`
		Persistent   bool    `json:"persistent"`
		Faction      string  `json:"faction"`
	}
	if err := decode(r, &req); err != nil {
		jsonErr(w, err, 400)
		return
	}
	if req.FlsID == "" || req.ClassName == "" {
		jsonErr(w, fmt.Errorf("fls_id and class_name required"), 400)
		return
	}
	if err := rmqSpawnVehicleAt(req.FlsID, req.ClassName, req.X, req.Y, req.Z, req.Rotation, req.TemplateName, req.Persistent, req.Faction); err != nil {
		jsonErr(w, err, 500)
		return
	}
	jsonOK(w, map[string]string{"ok": fmt.Sprintf("spawn %s command sent for %s", req.ClassName, req.FlsID)})
}

// @Summary Send whisper message to a player via RabbitMQ (experimental)
// @Tags players
// @Accept json
// @Produce json
// @Param body body object true "Target FLS ID, target name, sender name, message, and optional impersonated FLS ID"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/v1/chat/whisper [post]
// GET /api/v1/players/{id}/player-ids
// POST /api/v1/chat/whisper
//
// EXPERIMENTAL — first attempt at an external chat publish per Adain's
// chat-and-courier.md. The wire format is reconstructed from IDA/DWARF
// evidence; live external publish wasn't pinned by Adain, so the message
// may be silently dropped by the game even though the broker accepts it.
// Iterate based on what the target sees in-game.
func handleRMQWhisper(w http.ResponseWriter, r *http.Request) {
	var req struct {
		TargetFlsID       string `json:"target_fls_id"`
		TargetName        string `json:"target_name"`
		SenderName        string `json:"sender_name"`
		Message           string `json:"message"`
		ImpersonatedFlsID string `json:"impersonated_fls_id,omitempty"`
	}
	if err := decode(r, &req); err != nil {
		jsonErr(w, err, 400)
		return
	}
	if req.TargetFlsID == "" || req.Message == "" {
		jsonErr(w, fmt.Errorf("target_fls_id and message required"), 400)
		return
	}
	if req.SenderName == "" {
		req.SenderName = "GM"
	}
	if err := rmqSendWhisper(req.TargetFlsID, req.TargetName, req.SenderName, req.Message, req.ImpersonatedFlsID); err != nil {
		jsonErr(w, err, 500)
		return
	}
	jsonOK(w, map[string]string{
		"ok":   fmt.Sprintf("whisper sent to %s (broker accepted; in-game delivery is experimental)", req.TargetFlsID),
		"note": "Adain's chat publish recipe is not live-tested externally — check the target's whispers tab to confirm delivery.",
	})
}

// @Summary Resolve actor ID to both ID forms and render a sample RMQ envelope
// @Tags players
// @Produce json
// @Param id path int true "Actor (pawn) ID"
// @Success 200 {object} map[string]any
// @Failure 400 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Router /api/v1/players/{id}/player-ids [get]
// Returns both ID forms for an actor so you can verify which PlayerId the
// game server would receive. Also renders a sample AddItemToInventory envelope
// (without sending it) so the exact message format can be confirmed.
func handlePlayerIDDebug(w http.ResponseWriter, r *http.Request) {
	idStr := r.PathValue("id")
	actorID, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		jsonErr(w, fmt.Errorf("invalid actor id %q", idStr), 400)
		return
	}

	ctx := context.Background()
	ids, err := playerIDDebug(ctx, actorID)
	if err != nil {
		jsonErr(w, err, 404)
		return
	}

	// Build a sample envelope to show what the game server receives.
	inner, _ := json.Marshal(map[string]any{
		"ServerCommand": "AddItemToInventory",
		"PlayerId":      ids["hex_id"],
		"ItemName":      "<item_template>",
		"Quantity":      1,
		"Durability":    1.0,
	})
	outer := map[string]any{
		"Version":        2,
		"AuthToken":      serverCmdAuthToken,
		"MessageContent": string(inner),
	}

	jsonOK(w, map[string]any{
		"actor_id":        actorID,
		"display_name":    ids["display_name"],
		"hex_id":          ids["hex_id"],
		"player_id_field": ids["hex_id"],
		"auth_token":      serverCmdAuthToken,
		"publish_method":  "rabbitmqctl eval (user_id=fls)",
		"sample_envelope": outer,
	})
}
