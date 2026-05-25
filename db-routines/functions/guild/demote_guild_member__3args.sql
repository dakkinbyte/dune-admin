-- demote_guild_member(in_guild_id bigint, in_player_id bigint, in_new_role smallint) -> void
-- oid: 58233  kind: FUNCTION  category: guild

CREATE OR REPLACE FUNCTION dune.demote_guild_member(in_guild_id bigint, in_player_id bigint, in_new_role smallint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	PERFORM guilds_get_exclusive_operation_lock();

	-- check if new admin is actualy in guild
	IF NOT EXISTS(SELECT FROM guild_members WHERE player_id = in_player_id AND guild_id = in_guild_id) THEN
    	RAISE EXCEPTION 'Trying to demote player not in guild %.', in_player_id;
	END IF;

	IF is_player_guild_admin(in_player_id, in_guild_id) THEN
		RAISE EXCEPTION 'Trying to demote admin. promote a member to admin instead.';
	END IF;

	if in_new_role = 100 THEN
		RAISE EXCEPTION 'Trying to demote to admin.';
	END IF;

	-- set new player to new role
	UPDATE guild_members SET role_id = in_new_role WHERE player_id = in_player_id AND guild_id = in_guild_id;

	PERFORM pg_notify('guild_notify_channel', format('demote_player#{"PlayerId" : %s , "GuildId" : %s, "NewRole" : %s}', in_player_id, in_guild_id, in_new_role));
END
$function$
