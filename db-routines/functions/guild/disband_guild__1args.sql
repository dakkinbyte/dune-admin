-- disband_guild(in_guild_id bigint) -> void
-- oid: 58237  kind: FUNCTION  category: guild

CREATE OR REPLACE FUNCTION dune.disband_guild(in_guild_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	out_guild_name TEXT;
	members_list BIGINT[];
BEGIN
	PERFORM guilds_get_exclusive_operation_lock();

	-- check if guild exists
	SELECT guild_name INTO out_guild_name FROM guilds WHERE guild_id = in_guild_id;
	IF NOT FOUND THEN
    	RAISE EXCEPTION 'Trying to disband non existing guild %.', in_guild_id;
	END IF;

	-- get members list
	members_list := ARRAY(SELECT player_id FROM guild_members WHERE guild_id = in_guild_id);

	-- delete
	DELETE FROM guilds WHERE guild_id = in_guild_id;

	PERFORM pg_notify('guild_notify_channel', format('guild_disband#{"GuildId" : %s , "GuildName" : "%s", "PlayerIds" : %s}', in_guild_id, out_guild_name, to_json(members_list)::text));
END
$function$
