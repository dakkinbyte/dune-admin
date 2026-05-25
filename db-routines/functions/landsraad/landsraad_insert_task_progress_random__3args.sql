-- landsraad_insert_task_progress_random(in_term_id bigint, in_faction_names text[], in_num_rows integer) -> void
-- oid: 58416  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_insert_task_progress_random(in_term_id bigint, in_faction_names text[], in_num_rows integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	player_id BIGINT = NULL;
	guild_id BIGINT = NULL;
	house_name TEXT = NULL;
	random_amount INTEGER = NULL;
BEGIN
	FOR r IN 1..in_num_rows
	LOOP
		SELECT guild_members.player_id, guilds.guild_id FROM guilds 
			LEFT JOIN factions ON guilds.guild_faction = factions.id
			RIGHT JOIN guild_members ON guild_members.guild_id = guilds.guild_id
			WHERE factions.name = ANY(in_faction_names)
			ORDER BY random() LIMIT 1 INTO player_id, guild_id;
		SELECT tasks.house_name FROM landsraad_tasks tasks
			WHERE tasks.term_id = in_term_id 
			ORDER BY random() LIMIT 1 INTO house_name;
		SELECT (floor(random() * 5) + 1)::INTEGER * 10 INTO random_amount;
		IF player_id IS NOT NULL AND house_name IS NOT NULL THEN
			PERFORM landsraad_insert_task_progress(in_term_id, player_id, guild_id, house_name, random_amount * 10, (random_amount * 0.1)::REAL, (random_amount * 10)::REAL, now() AT TIME ZONE 'UTC');
		END IF;
	END LOOP;
END $function$
