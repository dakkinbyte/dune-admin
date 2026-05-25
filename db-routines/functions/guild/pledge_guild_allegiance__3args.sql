-- pledge_guild_allegiance(in_guild_id bigint, in_guild_leader_player_id bigint, in_neutral_faction_id smallint) -> void
-- oid: 58496  kind: FUNCTION  category: guild

CREATE OR REPLACE FUNCTION dune.pledge_guild_allegiance(in_guild_id bigint, in_guild_leader_player_id bigint, in_neutral_faction_id smallint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	guilds_changed SMALLINT := 0;
	guild_data_record record;
	guild_leader_record record;
	guild_leader_faction_id SMALLINT;
BEGIN
	PERFORM guilds_get_exclusive_operation_lock();

	SELECT * INTO guild_leader_record FROM guild_members
	LEFT JOIN player_faction ON actor_id = in_guild_leader_player_id
	WHERE player_id = in_guild_leader_player_id AND is_player_guild_admin(in_guild_leader_player_id, in_guild_id);

	IF guild_leader_record IS NULL THEN
		RAISE EXCEPTION 'Trying to change a faction for a player: % without a guild', in_guild_leader_player_id;
	END IF;

	SELECT * INTO guild_data_record FROM guilds WHERE guild_id = in_guild_id;
	IF guild_data_record IS NULL THEN
		RAISE EXCEPTION 'Trying to change a faction in non existing guild: %', in_guild_id;
	END IF;

	IF guild_leader_record.faction_id IS NULL THEN
		guild_leader_faction_id := in_neutral_faction_id;
    ELSE
		guild_leader_faction_id := guild_leader_record.faction_id;
	END IF;

	if guild_leader_faction_id = in_neutral_faction_id THEN
		RAISE EXCEPTION 'Guild leader has neutral faction, cannot change faction to neutral';
	ELSEIF guild_data_record.guild_faction = guild_leader_faction_id THEN
		RAISE EXCEPTION 'Guild already has the same allegiance: % as the guild leader %', in_guild_id, guild_data_record.guild_faction;
	END IF;

	UPDATE guilds SET guild_faction = guild_leader_faction_id WHERE guilds.guild_id = in_guild_id;

	PERFORM pg_notify('guild_notify_channel', format('pledge_guild_allegiance#{"GuildId" : %s , "OldGuildFactionDbId" : %s, "NewGuildFactionDbId" : %s}', in_guild_id, guild_data_record.guild_faction, guild_leader_faction_id));
	PERFORM remove_guild_members(ARRAY(
		SELECT player_id FROM guild_members
		JOIN player_faction ON guild_members.player_id = player_faction.actor_id
		WHERE guild_leader_faction_id != player_faction.faction_id AND player_faction.faction_id != in_neutral_faction_id AND guild_members.guild_id = in_guild_id),
		in_guild_id,
		2::smallint
	);
END
$function$
