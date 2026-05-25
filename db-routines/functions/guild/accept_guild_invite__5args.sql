-- accept_guild_invite(in_invite_id bigint, in_role_id smallint, in_max_guild_count_per_player integer, in_max_members_per_guild integer, in_neutral_faction_id smallint) -> void
-- oid: 58116  kind: FUNCTION  category: guild

CREATE OR REPLACE FUNCTION dune.accept_guild_invite(in_invite_id bigint, in_role_id smallint, in_max_guild_count_per_player integer, in_max_members_per_guild integer, in_neutral_faction_id smallint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	member_count INTEGER := 0;
	player_id BIGINT := 0;
	found_guild_id BIGINT := 0;
BEGIN
	PERFORM guilds_get_exclusive_operation_lock();

	-- check if invite exists
	SELECT guild_invites.player_id, guild_invites.guild_id FROM guild_invites WHERE invite_id = in_invite_id INTO player_id, found_guild_id;
	IF NOT FOUND THEN
    	RAISE EXCEPTION 'Trying to accept non exiting invite %.', in_invite_id;
	END IF;

	-- delete invite
	DELETE FROM guild_invites WHERE invite_id = in_invite_id;

	SELECT INTO member_count COUNT(*) FROM guild_members where guild_members.guild_id = found_guild_id;

	-- check if we've reached guild member limit
	IF member_count >= in_max_members_per_guild THEN
		RAISE EXCEPTION 'Cannot insert more than % members per guild.', in_max_members_per_guild;
	END IF;

	-- add member
	PERFORM add_guild_member(player_id, found_guild_id, in_role_id, in_max_guild_count_per_player, in_max_members_per_guild, in_neutral_faction_id);
END
$function$
