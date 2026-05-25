-- promote_guild_member(in_guild_id bigint, in_player_id bigint, in_new_role smallint) -> void
-- oid: 58498  kind: FUNCTION  category: guild

CREATE OR REPLACE FUNCTION dune.promote_guild_member(in_guild_id bigint, in_player_id bigint, in_new_role smallint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	PERFORM guilds_get_exclusive_operation_lock();

	-- check if new admin is actualy in guild
	IF NOT EXISTS(SELECT FROM guild_members WHERE player_id = in_player_id AND guild_id = in_guild_id) THEN
    	RAISE EXCEPTION 'Trying to promte player not in guild %.', in_player_id;
	END IF;

	if in_new_role = 100 THEN
		-- set admin to member
		UPDATE guild_members SET role_id = 50 WHERE guild_id = in_guild_id AND role_id = 100;
	END IF;

	-- set new player to new role
	UPDATE guild_members SET role_id = in_new_role WHERE player_id = in_player_id AND guild_id = in_guild_id;

	PERFORM pg_notify('guild_notify_channel', format('promote_player#{"PlayerId" : %s , "GuildId" : %s, "NewRole" : %s}', in_player_id, in_guild_id, in_new_role));
END
$function$
