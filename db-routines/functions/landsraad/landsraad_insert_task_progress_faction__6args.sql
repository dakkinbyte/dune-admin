-- landsraad_insert_task_progress_faction(in_term_id bigint, in_faction_name text, in_house_name text, in_faction_progress integer, in_guild_progress real, in_player_progress real) -> void
-- oid: 58415  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_insert_task_progress_faction(in_term_id bigint, in_faction_name text, in_house_name text, in_faction_progress integer, in_guild_progress real, in_player_progress real)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	player_id BIGINT = NULL;
	guild_id BIGINT = NULL;
BEGIN
	SELECT guild_members.player_id, guilds.guild_id FROM guilds 
		LEFT JOIN factions ON guilds.guild_faction = factions.id
		RIGHT JOIN guild_members ON guild_members.guild_id = guilds.guild_id
		WHERE factions.name = in_faction_name
		ORDER BY random() LIMIT 1 INTO player_id, guild_id;
	
	IF player_id IS NULL THEN 
		RAISE EXCEPTION 'Cannot insert landsraad task progress for faction %, no guild member found', in_faction_name;
	END IF;
	
	PERFORM landsraad_insert_task_progress(in_term_id, player_id, guild_id, in_house_name, in_faction_progress, in_guild_progress, in_player_progress, now() AT TIME ZONE 'UTC');
END $function$
