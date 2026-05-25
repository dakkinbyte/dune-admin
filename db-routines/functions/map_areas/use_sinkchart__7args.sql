-- use_sinkchart(in_player_id bigint, in_account_id bigint, in_area_id smallint, in_item_id bigint, in_sinkchart_map_name text, in_player_map_name text, in_player_current_dimension integer) -> dune.usesinkchartreturndata
-- oid: 58648  kind: FUNCTION  category: map_areas

CREATE OR REPLACE FUNCTION dune.use_sinkchart(in_player_id bigint, in_account_id bigint, in_area_id smallint, in_item_id bigint, in_sinkchart_map_name text, in_player_map_name text, in_player_current_dimension integer)
 RETURNS dune.usesinkchartreturndata
 LANGUAGE plpgsql
AS $function$
DECLARE
    sinkchart_markers SinkchartMarkerData[];
    survey_target JSONB;
BEGIN
    -- Update map areas.
    INSERT INTO map_areas (account_id, time_first_entered, time_discovered, area_id, items_surveyed_target, map_name)
    SELECT in_account_id, NULL, NOW(), in_area_id, map_areas.items_surveyed_target, in_sinkchart_map_name
    FROM map_areas
    WHERE map_areas.area_id = in_area_id
      AND map_areas.map_name = in_sinkchart_map_name
      AND map_areas.items_surveyed_target IS NOT NULL
    LIMIT 1
    ON CONFLICT ON CONSTRAINT map_areas_pkey DO UPDATE
        SET items_surveyed_target = EXCLUDED.items_surveyed_target,
            time_discovered = CASE WHEN map_areas.time_discovered IS NULL THEN EXCLUDED.time_discovered ELSE map_areas.time_discovered END
    RETURNING items_surveyed_target INTO survey_target;

    -- Perform the INSERT operation explicitly.
    INSERT INTO player_markers (player_id, marker_hash_id, dimension_index, map_name_id, discovery_level, discovery_method, payload)
    SELECT DISTINCT ON (m.marker_hash_id, m.dimension_index)
        in_player_id, m.marker_hash_id, m.dimension_index, m.map_name_id, /*discovery_level*/ 2, /*discovery_method*/ 12, /*payload*/ '{}'::JSONB
    FROM (
        SELECT UNNEST(sc.marker_hash_ids) AS marker_hash_id
        FROM sinkcharts sc
        WHERE sc.item_id = in_item_id
    ) expanded_ids
    JOIN map_names mn
        ON mn.map_name = in_sinkchart_map_name
    INNER JOIN markers m
        ON expanded_ids.marker_hash_id = m.marker_hash_id AND m.map_name_id = mn.map_name_id
    ORDER BY m.marker_hash_id, m.dimension_index
    ON CONFLICT ON CONSTRAINT player_markers_pkey DO UPDATE
        SET discovery_level = GREATEST(player_markers.discovery_level, EXCLUDED.discovery_level);

    -- Get markers that should be shown to the player immediately (marker on same map and dimension).
    SELECT ARRAY_AGG(ROW(m.marker_hash_id, m.marker, m.area_id, m.area_radius, m.long_range, pm.payload, m.payload)::SinkchartMarkerData)
    INTO sinkchart_markers
    FROM (
        SELECT UNNEST(sc.marker_hash_ids) AS marker_hash_id
        FROM sinkcharts sc
        WHERE sc.item_id = in_item_id
    ) expanded_ids
    JOIN map_names smn
        ON smn.map_name = in_sinkchart_map_name
    INNER JOIN markers m
        ON expanded_ids.marker_hash_id = m.marker_hash_id AND m.map_name_id = smn.map_name_id
    INNER JOIN player_markers pm
        ON m.marker_hash_id = pm.marker_hash_id
        AND m.dimension_index = pm.dimension_index
        AND m.map_name_id = pm.map_name_id
        AND pm.player_id = in_player_id
    JOIN map_names pmn
        ON pmn.map_name = in_player_map_name
    WHERE m.map_name_id = pmn.map_name_id
      AND (m.dimension_index = -1 OR m.dimension_index = in_player_current_dimension);

    RETURN (sinkchart_markers, survey_target);
END;
$function$
