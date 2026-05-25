-- load_events_log_data_from_player(in_actor_id bigint, in_limit_entries_num integer) -> TABLE(game_event_owner bigint, universe_time timestamp without time zone, map_name text, partition_id bigint, event_type integer, x_location double precision, y_location double precision, z_location double precision, custom_data jsonb)
-- oid: 58453  kind: FUNCTION  category: misc

CREATE OR REPLACE FUNCTION dune.load_events_log_data_from_player(in_actor_id bigint, in_limit_entries_num integer)
 RETURNS TABLE(game_event_owner bigint, universe_time timestamp without time zone, map_name text, partition_id bigint, event_type integer, x_location double precision, y_location double precision, z_location double precision, custom_data jsonb)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY
	SELECT temp.actor_id, (temp.universe_time AT TIME ZONE 'UTC')::TIMESTAMP, temp.map, temp.partition_id, temp.event_type, temp.x, temp.y, temp.z, temp.custom_data 
	FROM (SELECT game_events.actor_id, game_events.universe_time, game_events.map, game_events.partition_id, game_events.event_type, game_events.x, game_events.y, game_events.z, game_events.custom_data FROM game_events WHERE game_events.actor_id = in_actor_id AND game_events.player_facing_event = true ORDER BY game_events.universe_time DESC LIMIT in_limit_entries_num) temp 
	ORDER BY temp.universe_time ASC;
END
$function$
