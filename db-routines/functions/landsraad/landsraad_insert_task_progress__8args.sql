-- landsraad_insert_task_progress(in_term_id bigint, in_player_id bigint, in_guild_id bigint, in_house_name text, in_faction_progress integer, in_guild_progress real, in_player_progress real, in_timestamp timestamp without time zone) -> void
-- oid: 58413  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_insert_task_progress(in_term_id bigint, in_player_id bigint, in_guild_id bigint, in_house_name text, in_faction_progress integer, in_guild_progress real, in_player_progress real, in_timestamp timestamp without time zone)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	guild_id BIGINT = NULL;
	faction_id BIGINT = NULL;
	faction_name TEXT = NULL;
	progress_id BIGINT = NULL;
BEGIN

	IF in_player_id IS NULL THEN
		-- use guild_id
		SELECT guilds.guild_id, factions.id, factions.name FROM guild_members 
			INNER JOIN guilds ON guild_members.guild_id = guilds.guild_id 
			LEFT JOIN factions ON guilds.guild_faction = factions.id
			WHERE guild_members.guild_id = in_guild_id INTO guild_id, faction_id, faction_name;
	ELSE
		-- use player_id
		SELECT guilds.guild_id, factions.id, factions.name FROM guild_members 
			INNER JOIN guilds ON guild_members.guild_id = guilds.guild_id 
			LEFT JOIN factions ON guilds.guild_faction = factions.id
			WHERE guild_members.player_id = in_player_id INTO guild_id, faction_id, faction_name;
	END IF;

	IF guild_id IS NULL THEN
		RAISE EXCEPTION 'Cannot insert landsraad task progress, player % not in guild', in_player_id;
	END IF;

	IF faction_id IS NULL OR faction_name = 'None' THEN 
		RAISE EXCEPTION 'Cannot insert landsraad task progress, guild % not aligned to faction', guild_id;
	END IF;

	INSERT INTO landsraad_task_progress (faction_id, task_id, faction_progress, guild_progress, player_progress, timestamp) 
		SELECT faction_id, tasks.id, in_faction_progress, in_guild_progress, in_player_progress, in_timestamp AT TIME ZONE 'UTC'
		FROM landsraad_tasks AS tasks 
		WHERE tasks.term_id = in_term_id AND tasks.house_name = in_house_name
		RETURNING id INTO progress_id;

	IF in_player_id IS NOT NULL THEN
		INSERT INTO landsraad_task_progress_player (progress_id, player_id) VALUES (progress_id, in_player_id);
	END IF;

	INSERT INTO landsraad_task_progress_guild (progress_id, guild_id) VALUES (progress_id, guild_id);

END $function$
