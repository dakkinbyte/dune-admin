-- remove_guild_members(in_player_ids bigint[], in_guild_id bigint, in_remove_reason smallint) -> void
-- oid: 58518  kind: FUNCTION  category: guild

CREATE OR REPLACE FUNCTION dune.remove_guild_members(in_player_ids bigint[], in_guild_id bigint, in_remove_reason smallint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	out_guild_name TEXT;
	players_removed BIGINT[];
BEGIN
	PERFORM guilds_get_exclusive_operation_lock();

	-- check if guild exists
	SELECT guild_name INTO out_guild_name FROM guilds WHERE guild_id = in_guild_id;
	IF NOT FOUND THEN
    	RAISE EXCEPTION 'Trying to disband non existing guild %.', in_guild_id;
	END IF;

	WITH removed_members AS (
		DELETE FROM guild_members
		WHERE player_id = ANY(in_player_ids) AND NOT is_player_guild_admin(player_id, in_guild_id)
		RETURNING *
	) SELECT array_agg(player_id) from removed_members INTO players_removed;

	PERFORM pg_notify('guild_notify_channel', format('remove_players#{"PlayerIds" : [%s] , "GuildId" : %s, "GuildName" : "%s", "GuildRemoveReason" : %s}', ARRAY_TO_STRING(players_removed, ','), in_guild_id, out_guild_name, in_remove_reason));
END
$function$
