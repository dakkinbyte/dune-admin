-- delete_markers_for_all_players(in_marker_types_to_keep text[], in_map text) -> void
-- oid: 58225  kind: FUNCTION  category: markers

CREATE OR REPLACE FUNCTION dune.delete_markers_for_all_players(in_marker_types_to_keep text[], in_map text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	-- Lock markers matching query
	WITH affected_markers AS (
		SELECT * FROM markers JOIN map_names USING(map_name_id)
		WHERE (in_map IS NULL OR map_names.map_name = in_map) AND NOT (marker).marker_type = ANY(in_marker_types_to_keep)
		ORDER BY marker_hash_id, dimension_index, map_name_id FOR UPDATE -- Ordering to avoid deadlocks
	),
	-- Lock player_markers to be deleted on cascade
	referencing_player_markers AS (
		SELECT player_markers.* FROM player_markers, affected_markers
		WHERE affected_markers.marker_hash_id = player_markers.marker_hash_id
			AND affected_markers.dimension_index = player_markers.dimension_index
			AND affected_markers.map_name_id = player_markers.map_name_id
		ORDER BY player_id, player_markers.marker_hash_id, player_markers.dimension_index, player_markers.map_name_id FOR UPDATE -- Ordering to avoid deadlocks
	)
	-- Delete markers
	DELETE FROM markers USING affected_markers
	WHERE affected_markers.marker_hash_id = markers.marker_hash_id
		AND affected_markers.dimension_index = markers.dimension_index
		AND affected_markers.map_name_id = markers.map_name_id;
END;
$function$
