-- edit_guild_description(in_guild_id bigint, in_guild_desc text) -> void
-- oid: 58258  kind: FUNCTION  category: currency

CREATE OR REPLACE FUNCTION dune.edit_guild_description(in_guild_id bigint, in_guild_desc text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	out_guild_description TEXT;
BEGIN
	PERFORM guilds_get_exclusive_operation_lock();

	-- check if guild exists
	SELECT guild_description INTO out_guild_description FROM guilds WHERE guild_id = in_guild_id;
	IF NOT FOUND THEN
    	RAISE EXCEPTION 'Trying to add invite to non existing guild %.', in_guild_id;
	END IF;

	UPDATE guilds SET guild_description = in_guild_desc WHERE guilds.guild_id = in_guild_id;

	PERFORM pg_notify('guild_notify_channel', format('edit_guild_description#{"GuildId" : %s}', in_guild_id));
END
$function$
