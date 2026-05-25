-- get_landclaim_segments(in_totem_id bigint) -> TABLE(grid_location_x bigint, grid_location_y bigint)
-- oid: 58315  kind: FUNCTION  category: landclaim

CREATE OR REPLACE FUNCTION dune.get_landclaim_segments(in_totem_id bigint)
 RETURNS TABLE(grid_location_x bigint, grid_location_y bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT t.grid_location_x, t.grid_location_y
    FROM landclaim_segments AS t
    WHERE t.totem_id = in_totem_id;
END; $function$
