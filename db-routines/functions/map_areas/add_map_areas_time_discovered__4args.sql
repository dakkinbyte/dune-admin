-- add_map_areas_time_discovered(in_account_id bigint, in_area_id smallint, in_time_discovered timestamp without time zone, in_map_name text) -> void
-- oid: 58125  kind: FUNCTION  category: map_areas

CREATE OR REPLACE FUNCTION dune.add_map_areas_time_discovered(in_account_id bigint, in_area_id smallint, in_time_discovered timestamp without time zone, in_map_name text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO map_areas("account_id", "area_id", "time_discovered", "map_name")
        VALUES(in_account_id, in_area_id, in_time_discovered, in_map_name)
        ON CONFLICT ("account_id", "area_id", "map_name") DO UPDATE SET "time_discovered" = in_time_discovered
        WHERE map_areas.account_id = in_account_id AND map_areas.area_id = in_area_id and map_areas.map_name = in_map_name;
END;
$function$
