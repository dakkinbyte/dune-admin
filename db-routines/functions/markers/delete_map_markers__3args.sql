-- delete_map_markers(in_dimension_index integer, in_map_name text, in_player_marker_data dune.deleteplayermarkerdata[]) -> void
-- oid: 58222  kind: FUNCTION  category: markers

CREATE OR REPLACE FUNCTION dune.delete_map_markers(in_dimension_index integer, in_map_name text, in_player_marker_data dune.deleteplayermarkerdata[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	WITH player_hash_ids AS (SELECT player_id, marker_hash_ids FROM UNNEST(in_player_marker_data)),
	player_markers_to_delete AS (
		SELECT player_markers.* FROM player_hash_ids, player_markers JOIN map_names USING(map_name_id)
		WHERE (player_markers.dimension_index = in_dimension_index OR player_markers.dimension_index = -1)
			AND map_names.map_name = in_map_name
			AND player_markers.player_id = player_hash_ids.player_id
			AND player_markers.marker_hash_id = ANY(player_hash_ids.marker_hash_ids)
		ORDER BY player_markers.player_id, player_markers.marker_hash_id, player_markers.dimension_index FOR UPDATE -- Ordering for deadlock avoidance
	)
	DELETE FROM player_markers USING player_markers_to_delete
	WHERE player_markers.dimension_index = player_markers_to_delete.dimension_index
		AND player_markers.map_name_id = player_markers_to_delete.map_name_id
		AND player_markers.player_id = player_markers_to_delete.player_id
		AND player_markers.marker_hash_id = player_markers_to_delete.marker_hash_id;
END;
$function$
