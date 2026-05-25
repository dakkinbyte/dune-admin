-- load_markers(in_player_id bigint, in_dimension_id integer, in_map_name text) -> TABLE(out_marker_hash_id integer, out_marker_type text, out_x double precision, out_y double precision, out_z double precision, out_payload_type text, out_area_id smallint, out_area_radius real, out_long_range boolean, out_payload jsonb, out_discovery_level smallint, out_discovery_method smallint, out_player_payload jsonb)
-- oid: 58458  kind: FUNCTION  category: markers

CREATE OR REPLACE FUNCTION dune.load_markers(in_player_id bigint, in_dimension_id integer, in_map_name text)
 RETURNS TABLE(out_marker_hash_id integer, out_marker_type text, out_x double precision, out_y double precision, out_z double precision, out_payload_type text, out_area_id smallint, out_area_radius real, out_long_range boolean, out_payload jsonb, out_discovery_level smallint, out_discovery_method smallint, out_player_payload jsonb)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY
   		SELECT
			player_markers.marker_hash_id,
			(markers.marker).marker_type,
			(markers.marker).x,
			(markers.marker).y,
			(markers.marker).z,
			(markers.marker).payload_type,
			area_id,
			area_radius,
			long_range,
			markers.payload,
			discovery_level,
			discovery_method,
			player_markers.payload
		FROM map_names JOIN markers ON markers.map_name_id = map_names.map_name_id
			JOIN player_markers ON markers.marker_hash_id = player_markers.marker_hash_id
			AND markers.dimension_index = player_markers.dimension_index
			AND markers.map_name_id = player_markers.map_name_id
		WHERE player_markers.player_id = in_player_id
			AND (player_markers.dimension_index = in_dimension_id OR player_markers.dimension_index = -1)
			AND map_names.map_name = in_map_name;
END
$function$
