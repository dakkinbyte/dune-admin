-- clean_guild_invites_with_incompatible_faction(in_player_id bigint, in_faction_id smallint, neutral_faction_id smallint) -> void
-- oid: 58166  kind: FUNCTION  category: faction

CREATE OR REPLACE FUNCTION dune.clean_guild_invites_with_incompatible_faction(in_player_id bigint, in_faction_id smallint, neutral_faction_id smallint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	row_record record; -- Variable to hold individual rows
	out_guild_faction_id SMALLINT;
BEGIN
	PERFORM guilds_get_exclusive_operation_lock();

	FOR row_record IN
		SELECT invite_id, guild_invites.guild_id, guilds.guild_faction FROM get_player_guild_invites(in_player_id) as guild_invites
		JOIN guilds ON guilds.guild_id = guild_invites.guild_id
	LOOP	
		IF row_record.guild_faction != neutral_faction_id AND in_faction_id != neutral_faction_id AND row_record.guild_faction != in_faction_id THEN
			PERFORM reject_guild_invite(row_record.invite_id);
		END IF;
    END LOOP;
END
$function$
