-- create_sinkchart_for_map_area_id(in_item_id bigint, in_creator_id bigint, in_map_name text, in_area_id smallint) -> integer
-- oid: 58186  kind: FUNCTION  category: map_areas

CREATE OR REPLACE FUNCTION dune.create_sinkchart_for_map_area_id(in_item_id bigint, in_creator_id bigint, in_map_name text, in_area_id smallint)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
	sinkchart_marker_ids BIGINT[];
	sinkchart_array_length INT;
BEGIN
	-- Aggregate marker hash IDs into an array based on the conditions
	SELECT ARRAY_AGG(markers.marker_hash_id) INTO sinkchart_marker_ids
	FROM player_markers,
         markers JOIN map_names USING(map_name_id)
	WHERE player_markers.player_id = in_creator_id
		AND map_names.map_name = in_map_name
		AND player_markers.map_name_id = markers.map_name_id
		AND player_markers.marker_hash_id = markers.marker_hash_id
		AND markers.area_id = in_area_id
		AND (player_markers.discovery_level = 2 OR player_markers.discovery_level = 3); -- 'EMarkerDiscoveryLevel::Mysterious' OR 'EMarkerDiscoveryLevel::Discovered'

	-- Check if is NOT NULL before proceeding with the INSERT
	IF array_length(sinkchart_marker_ids, 1) IS NOT NULL THEN
		INSERT INTO sinkcharts (item_id, marker_hash_ids)
		VALUES (in_item_id, sinkchart_marker_ids)
		RETURNING array_length(marker_hash_ids, 1) INTO sinkchart_array_length;

		RETURN sinkchart_array_length;
	ELSE
		RETURN 0;
	END IF;
END
$function$
