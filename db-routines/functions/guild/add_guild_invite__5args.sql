-- add_guild_invite(in_player_id bigint, in_guild_id bigint, in_sender_player_id bigint, in_invite_sent_timespan bigint, in_max_guild_invites_per_guild integer) -> void
-- oid: 58121  kind: FUNCTION  category: guild

CREATE OR REPLACE FUNCTION dune.add_guild_invite(in_player_id bigint, in_guild_id bigint, in_sender_player_id bigint, in_invite_sent_timespan bigint, in_max_guild_invites_per_guild integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	invite_count INTEGER := 0;
	out_invite_id INTEGER;
	out_guild_name TEXT;
	out_guild_description TEXT;
	out_player_name TEXT;
	out_sender_name TEXT;
BEGIN
	PERFORM guilds_get_exclusive_operation_lock();

	-- check if guild exists
	SELECT guild_name, guild_description INTO out_guild_name, out_guild_description FROM guilds WHERE guild_id = in_guild_id;
	IF NOT FOUND THEN
    	RAISE EXCEPTION 'Trying to add invite to non existing guild %.', in_guild_id;
	END IF;

	-- check if we've reached the invite limit
	SELECT INTO invite_count COUNT(*) FROM guild_invites WHERE guild_invites.guild_id = in_guild_id;
	IF invite_count >= in_max_guild_invites_per_guild THEN
		RAISE EXCEPTION 'Cannot insert more than % guild invites per guild.', in_max_guild_invites_per_guild;
	END IF;

	-- check if this player already has an invite to this guild
	IF EXISTS (SELECT FROM guild_invites WHERE guild_id = in_guild_id AND player_id = in_player_id) THEN
		RAISE EXCEPTION 'Trying to add invite to a player that already has an invite to this guild.';
	END IF;

	-- add invite
	INSERT INTO guild_invites("guild_id", "player_id", "sender_player_id", "invite_sent_timespan") VALUES(in_guild_id, in_player_id, in_sender_player_id, in_invite_sent_timespan) RETURNING "invite_id" INTO out_invite_id;

	SELECT player_state.character_name INTO out_player_name
	FROM player_state
	WHERE player_state.player_controller_id = in_player_id;

	SELECT player_state.character_name INTO out_sender_name
	FROM player_state
	WHERE player_state.player_controller_id = in_sender_player_id;

	PERFORM pg_notify('guild_notify_channel', format(
	'add_invite#{"InviteId" : %s, "PlayerId" : %s , "GuildId" : %s, "GuildName" : "%s", "PlayerName" : "%s", "GuildDescription" : "%s", "SenderPlayerId" : %s, "SenderPlayerName" : "%s", "InviteSentUniverseTime" : %s}',
	 out_invite_id, in_player_id, in_guild_id, out_guild_name, out_player_name, out_guild_description, in_sender_player_id, out_sender_name, in_invite_sent_timespan));
END
$function$
