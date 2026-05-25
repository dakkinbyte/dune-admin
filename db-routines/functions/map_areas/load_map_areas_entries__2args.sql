-- load_map_areas_entries(in_account_id bigint, in_map_name text) -> TABLE(account_id bigint, area_id smallint, time_discovered timestamp without time zone, time_first_entered timestamp without time zone, survey_point_marker_id bigint, items_surveyed_target jsonb, items_surveyed_progress jsonb, map_name text)
-- oid: 58457  kind: FUNCTION  category: map_areas

CREATE OR REPLACE FUNCTION dune.load_map_areas_entries(in_account_id bigint, in_map_name text)
 RETURNS TABLE(account_id bigint, area_id smallint, time_discovered timestamp without time zone, time_first_entered timestamp without time zone, survey_point_marker_id bigint, items_surveyed_target jsonb, items_surveyed_progress jsonb, map_name text)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
        SELECT
            map_areas.account_id,
            map_areas.area_id,
            map_areas.time_discovered AT TIME ZONE 'UTC',
            map_areas.time_first_entered AT TIME ZONE 'UTC',
            map_areas.survey_point_marker_id,
            map_areas.items_surveyed_target,
            map_areas.items_surveyed_progress,
            map_areas.map_name
        from map_areas WHERE map_areas.account_id = in_account_id AND map_areas.map_name = in_map_name;
END
$function$
