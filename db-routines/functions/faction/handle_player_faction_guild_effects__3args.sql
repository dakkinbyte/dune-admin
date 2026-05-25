-- handle_player_faction_guild_effects(in_player_id bigint, in_faction_id smallint, neutral_faction_id smallint) -> void
-- oid: 58368  kind: FUNCTION  category: faction

CREATE OR REPLACE FUNCTION dune.handle_player_faction_guild_effects(in_player_id bigint, in_faction_id smallint, neutral_faction_id smallint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	guild_member_record record;
BEGIN
	PERFORM guilds_get_exclusive_operation_lock();

	SELECT * INTO guild_member_record
	FROM guild_members
	JOIN guilds ON guilds.guild_id = guild_members.guild_id
	WHERE player_id = in_player_id;

	IF guild_member_record IS NOT NULL THEN
		PERFORM pg_notify('guild_notify_channel', format('player_guild_data_changed#{"GuildId" : %s , "PlayerId" : %s, "FactionId" : %s}', guild_member_record.guild_id, in_player_id, in_faction_id));
	 	IF guild_member_record.guild_faction != neutral_faction_id THEN
			-- If guild leader changes faction and guild already has a non neutral faction, break the guild allegiance
			IF is_player_guild_admin(in_player_id, guild_member_record.guild_id) THEN
				PERFORM break_guild_allegiance(guild_member_record.guild_id, neutral_faction_id);
			-- Neutral player changing to Faction A while Guild is Faction B must be kicked
			ELSEIF guild_member_record.guild_faction != in_faction_id AND in_faction_id != neutral_faction_id THEN
				PERFORM remove_guild_members(ARRAY[in_player_id], guild_member_record.guild_id, 2::smallint);
			END IF;
		END IF;
	END IF;
	PERFORM clean_guild_invites_with_incompatible_faction(in_player_id, in_faction_id, neutral_faction_id);
END
$function$
