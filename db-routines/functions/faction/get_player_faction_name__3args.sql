-- get_player_faction_name(in_actor_id bigint, OUT player_faction_name text, OUT utc_time_faction_change timestamp without time zone) -> record
-- oid: 58334  kind: FUNCTION  category: faction

CREATE OR REPLACE FUNCTION dune.get_player_faction_name(in_actor_id bigint, OUT player_faction_name text, OUT utc_time_faction_change timestamp without time zone)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
	SELECT factions.name, player_faction.utc_time_faction_change AT TIME ZONE 'UTC' INTO player_faction_name, utc_time_faction_change
	FROM factions INNER JOIN player_faction ON factions.id = player_faction.faction_id 
	WHERE player_faction.actor_id = in_actor_id 
	limit 1;
END; $function$
