-- add_guild_member(in_player_id bigint, in_guild_id bigint, in_role_id smallint, in_max_guild_count_per_player integer, in_max_members_per_guild integer, in_neutral_faction_id smallint) -> void
-- oid: 58122  kind: FUNCTION  category: guild

CREATE OR REPLACE FUNCTION dune.add_guild_member(in_player_id bigint, in_guild_id bigint, in_role_id smallint, in_max_guild_count_per_player integer, in_max_members_per_guild integer, in_neutral_faction_id smallint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	guild_count INTEGER := 0;
	should_clear_invites SMALLINT := 0;
	player_faction_id SMALLINT;
	guild_record record;
BEGIN
	PERFORM guilds_get_exclusive_operation_lock();

	-- we need to check if the player is already part of max amount of guilds before being able to add them
    SELECT INTO guild_count COUNT(*) FROM guild_members WHERE player_id = in_player_id;
    IF guild_count >= in_max_guild_count_per_player THEN
        RAISE EXCEPTION 'Cannot insert more than % guild entries for each user.', in_max_guild_count_per_player;
    END IF;

	SELECT * INTO guild_record
	FROM guilds
	WHERE guild_id = in_guild_id;

	-- check if guild exists
	IF guild_record IS NULL THEN
    	RAISE EXCEPTION 'Trying to add user to non existing guild %.', in_guild_id;
	END IF;

	player_faction_id := get_player_faction(in_player_id, in_neutral_faction_id);

	IF  player_faction_id != in_neutral_faction_id AND guild_record.guild_faction != in_neutral_faction_id AND player_faction_id != guild_record.guild_faction THEN
		RAISE EXCEPTION 'Trying to add user to with non compatible. player faction: %, guild faction: %', player_faction_id, guild_record.guild_faction;
	END IF;

	IF (SELECT COUNT(*) FROM guild_members where guild_members.guild_id = in_guild_id) = in_max_members_per_guild - 1 THEN
		should_clear_invites := 1;
	END IF;

	-- insert member
	INSERT INTO guild_members("player_id", "guild_id", "role_id") VALUES(in_player_id, in_guild_id, in_role_id);

	-- delete invite
    IF should_clear_invites = 1 THEN
        DELETE FROM guild_invites WHERE guild_id = in_guild_id;
    ELSE
	    DELETE FROM guild_invites WHERE guild_id = in_guild_id AND player_id = in_player_id;
    END IF;

	PERFORM pg_notify('guild_notify_channel', format('add_player#{"PlayerId" : %s , "PlayerFactionId" : %s, "GuildId" : %s, "RoleId" : %s, "ShouldClearInvites" : %s}', in_player_id, player_faction_id, in_guild_id, in_role_id, should_clear_invites));
END
$function$
