-- add_event_log_data(in_game_event_owner bigint, in_universe_time bigint, in_map_name text, in_partition_id bigint, in_event_type integer, in_x_location double precision, in_y_location double precision, in_z_location double precision, in_is_player_facing boolean, in_custom_data text) -> void
-- oid: 58119  kind: FUNCTION  category: event_log

CREATE OR REPLACE FUNCTION dune.add_event_log_data(in_game_event_owner bigint, in_universe_time bigint, in_map_name text, in_partition_id bigint, in_event_type integer, in_x_location double precision, in_y_location double precision, in_z_location double precision, in_is_player_facing boolean, in_custom_data text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	INSERT INTO game_events(actor_id, universe_time, map, partition_id, event_type, x, y, z, custom_data, player_facing_event) VALUES(in_game_event_owner, to_timestamp(in_universe_time), in_map_name, in_partition_id, in_event_type, in_x_location, in_y_location, in_z_location, in_custom_data::JsonB, in_is_player_facing);
END
$function$
