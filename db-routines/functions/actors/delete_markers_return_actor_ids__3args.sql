-- delete_markers_return_actor_ids(in_dimension_index integer, in_map_name text, in_marker_ids integer[]) -> TABLE(actor_id bigint, marker_id integer)
-- oid: 58226  kind: FUNCTION  category: actors

CREATE OR REPLACE FUNCTION dune.delete_markers_return_actor_ids(in_dimension_index integer, in_map_name text, in_marker_ids integer[])
 RETURNS TABLE(actor_id bigint, marker_id integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY
	-- Lock markers matching query
	WITH affected_markers AS (
		SELECT * FROM markers JOIN map_names USING(map_name_id)
		WHERE (dimension_index = in_dimension_index OR dimension_index = -1)
			AND map_names.map_name = in_map_name
			AND marker_hash_id = ANY(in_marker_ids)
		ORDER BY marker_hash_id, dimension_index FOR UPDATE -- Ordering to avoid deadlocks
	),
	-- Lock player_markers to be deleted on cascade
	referencing_player_markers AS (
		SELECT player_id, player_markers.marker_hash_id FROM player_markers, affected_markers
		WHERE affected_markers.marker_hash_id = player_markers.marker_hash_id
			AND affected_markers.dimension_index = player_markers.dimension_index
			AND affected_markers.map_name_id = player_markers.map_name_id
		ORDER BY player_id, player_markers.marker_hash_id, player_markers.dimension_index FOR UPDATE -- Ordering to avoid deadlocks
	),
	-- Delete markers
	deleted_markers AS (
		DELETE FROM markers USING affected_markers
		WHERE affected_markers.marker_hash_id = markers.marker_hash_id
			AND affected_markers.dimension_index = markers.dimension_index
			AND affected_markers.map_name_id = markers.map_name_id
	)
	SELECT * FROM referencing_player_markers;
END
$function$
