-- add_map_areas_surveyed_items(in_account_id bigint, in_area_id smallint, in_survey_point_marker_id bigint, in_surveyed_items_target jsonb, in_surveyed_items_progress jsonb, in_map_name text) -> void
-- oid: 58124  kind: FUNCTION  category: map_areas

CREATE OR REPLACE FUNCTION dune.add_map_areas_surveyed_items(in_account_id bigint, in_area_id smallint, in_survey_point_marker_id bigint, in_surveyed_items_target jsonb, in_surveyed_items_progress jsonb, in_map_name text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO map_areas("account_id", "area_id", "survey_point_marker_id", "items_surveyed_target", "items_surveyed_progress", "map_name")
        VALUES(in_account_id, in_area_id, in_survey_point_marker_id, in_surveyed_items_target, in_surveyed_items_progress, in_map_name)
        ON CONFLICT ("account_id", "area_id", "map_name") DO UPDATE SET "survey_point_marker_id" = in_survey_point_marker_id, "items_surveyed_target" = in_surveyed_items_target, "items_surveyed_progress" = in_surveyed_items_progress
        WHERE map_areas.account_id = in_account_id AND map_areas.area_id = in_area_id and map_areas.map_name = in_map_name;
END;
$function$
