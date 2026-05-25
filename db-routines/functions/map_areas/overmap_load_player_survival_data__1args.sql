-- overmap_load_player_survival_data(in_player_id bigint) -> TABLE(out_vehicle_id bigint, out_has_polar_psu boolean, out_overmap_location dune.vector)
-- oid: 58480  kind: FUNCTION  category: map_areas

CREATE OR REPLACE FUNCTION dune.overmap_load_player_survival_data(in_player_id bigint)
 RETURNS TABLE(out_vehicle_id bigint, out_has_polar_psu boolean, out_overmap_location dune.vector)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY SELECT vehicle_id, has_polar_psu, overmap_location FROM overmap_players WHERE player_id = in_player_id;
END $function$
