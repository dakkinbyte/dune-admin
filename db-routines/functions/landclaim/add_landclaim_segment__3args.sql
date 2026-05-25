-- add_landclaim_segment(in_totem_id bigint, in_grid_location_x bigint, in_grid_location_y bigint) -> void
-- oid: 58123  kind: FUNCTION  category: landclaim

CREATE OR REPLACE FUNCTION dune.add_landclaim_segment(in_totem_id bigint, in_grid_location_x bigint, in_grid_location_y bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO landclaim_segments(totem_id, grid_location_x, grid_location_y)
    VALUES(in_totem_id, in_grid_location_x, in_grid_location_y);
END; $function$
