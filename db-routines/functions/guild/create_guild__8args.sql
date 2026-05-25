-- create_guild(in_player_id bigint, in_neutral_faction smallint, in_guild_name text, in_guild_desc text, in_max_guild_count_per_player integer, OUT out_guild_id bigint, OUT out_success boolean, OUT out_fail_reason dune.guildcreatefailreason) -> record
-- oid: 58183  kind: FUNCTION  category: guild

CREATE OR REPLACE FUNCTION dune.create_guild(in_player_id bigint, in_neutral_faction smallint, in_guild_name text, in_guild_desc text, in_max_guild_count_per_player integer, OUT out_guild_id bigint, OUT out_success boolean, OUT out_fail_reason dune.guildcreatefailreason)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
	guild_count integer;
BEGIN
	PERFORM guilds_get_exclusive_operation_lock();

	IF EXISTS (SELECT 1 FROM guilds WHERE guild_name ILIKE in_guild_name) THEN
		out_guild_id := 0;
		out_success := FALSE;
		out_fail_reason := 'NameAlreadyTaken'::GuildCreateFailReason; -- 1 represents NAME_ALREADY_EXISTS
		RETURN;
	END IF;

	-- we need to check if the player is already part of max amount of guilds before being able to add them
	SELECT INTO guild_count COUNT(*) FROM guild_members WHERE player_id = in_player_id;
	IF guild_count >= in_max_guild_count_per_player THEN
		out_guild_id := 0;
		out_success := FALSE;
		out_fail_reason := 'QueryError'::GuildCreateFailReason;
		RETURN;
	END IF;

	INSERT INTO guilds("guild_id", "guild_name", "guild_faction", "guild_description") VALUES(DEFAULT, in_guild_name, in_neutral_faction , in_guild_desc) RETURNING "guild_id" INTO out_guild_id;
	INSERT INTO guild_members("player_id", "guild_id", "role_id") VALUES(in_player_id, out_guild_id, 100);

	PERFORM pg_notify('guild_notify_channel', format('add_player#{"PlayerId" : %s , "PlayerFactionId" : %s, "GuildId" : %s, "RoleId" : 100, "ShouldClearInvites" : 0}', in_player_id, get_player_faction(in_player_id, in_neutral_faction), out_guild_id));

	out_success := TRUE;
	out_fail_reason := 'None'::GuildCreateFailReason;
END
$function$
