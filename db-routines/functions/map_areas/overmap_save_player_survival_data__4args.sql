-- overmap_save_player_survival_data(in_player_id bigint, in_vehicle_id bigint, in_has_polar_psu boolean, in_overmap_location dune.vector) -> void
-- oid: 58481  kind: FUNCTION  category: map_areas

CREATE OR REPLACE FUNCTION dune.overmap_save_player_survival_data(in_player_id bigint, in_vehicle_id bigint, in_has_polar_psu boolean, in_overmap_location dune.vector)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	real_vehicle_id BigInt;
BEGIN
	real_vehicle_id := (select id from actors where id=in_vehicle_id);
	INSERT INTO
		overmap_players(player_id, vehicle_id, has_polar_psu, overmap_location) VALUES(in_player_id, real_vehicle_id, in_has_polar_psu, in_overmap_location)
	ON CONFLICT(player_id)
		DO UPDATE SET
			vehicle_id = real_vehicle_id, has_polar_psu = in_has_polar_psu, overmap_location = in_overmap_location
		WHERE
			overmap_players.player_id = in_player_id;
END $function$
