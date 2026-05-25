-- save_markers(in_player_marker_data dune.saveplayermarkerdata[], in_marker_data dune.savemarkerdata[]) -> void
-- oid: 58551  kind: FUNCTION  category: markers

CREATE OR REPLACE FUNCTION dune.save_markers(in_player_marker_data dune.saveplayermarkerdata[], in_marker_data dune.savemarkerdata[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	null_player_marker_map_id_count INTEGER;
	null_marker_map_id_count INTEGER;
BEGIN

	SELECT COUNT(*)
    INTO null_player_marker_map_id_count
	FROM UNNEST(in_player_marker_data) AS umd
	LEFT JOIN map_names AS mn ON umd.map_name = mn.map_name
    WHERE mn.map_name_id IS NULL; -- Find map name that doesn't exist

	IF null_player_marker_map_id_count > 0 THEN
        RAISE EXCEPTION 'Found records with NULL map name id for player markers!';
    END IF;

    SELECT COUNT(*)
    INTO null_marker_map_id_count
	FROM UNNEST(in_marker_data) AS umd
	LEFT JOIN map_names AS mn ON umd.map_name = mn.map_name
    WHERE mn.map_name_id IS NULL; -- Find map name that doesn't exist

	IF null_marker_map_id_count > 0 THEN
        RAISE EXCEPTION 'Found records with NULL map name id for markers!';
    END IF;

    INSERT INTO markers("marker_hash_id", "dimension_index", "map_name_id", "marker", "area_id", "area_radius", "long_range", "payload")
        SELECT
           	umd.marker_hash_id,
            umd.dimension_index,
            mn.map_name_id,
            umd.marker,
            umd.area_id,
            umd.area_radius,
            umd.long_range,
            umd.payload
        FROM UNNEST(in_marker_data) umd JOIN map_names mn USING(map_name)
    	ORDER BY marker_hash_id, dimension_index, map_name_id
    ON CONFLICT ON CONSTRAINT markers_pkey
        DO UPDATE SET
            "area_id" = EXCLUDED.area_id,
            "area_radius" = EXCLUDED.area_radius,
            "long_range" = EXCLUDED.long_range,
            "payload" = EXCLUDED.payload;

	WITH marker_data_for_existing_players AS (
    	SELECT
			player_data.player_id,
			player_data.marker_hash_id,
			player_data.dimension_index,
			mn.map_name_id,
			player_data.discovery_level,
			player_data.discovery_method,
			player_data.player_payload
    	FROM UNNEST(in_player_marker_data) AS player_data
    	JOIN actors ON actors.id = player_data.player_id
    	JOIN map_names mn USING(map_name)
	)
	INSERT INTO player_markers("player_id", "marker_hash_id", "dimension_index", "map_name_id", "discovery_level", "discovery_method", "payload")
		SELECT
			in_data.player_id,
			in_data.marker_hash_id,
			in_data.dimension_index,
			in_data.map_name_id,
			in_data.discovery_level,
			in_data.discovery_method,
			in_data.player_payload
		FROM marker_data_for_existing_players AS in_data, markers
		WHERE markers.marker_hash_id = in_data.marker_hash_id AND markers.dimension_index = in_data.dimension_index AND markers.map_name_id = in_data.map_name_id
		ORDER BY player_id, in_data.marker_hash_id, in_data.dimension_index, in_data.map_name_id -- Ordering for deadlock avoidance
	ON CONFLICT ON CONSTRAINT player_markers_pkey
		DO UPDATE SET
			"discovery_level" = EXCLUDED.discovery_level,
			"discovery_method" = EXCLUDED.discovery_method,
			"payload" = EXCLUDED.payload;
END
$function$
