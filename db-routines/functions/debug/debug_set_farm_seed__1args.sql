-- debug_set_farm_seed(in_new_coriolis_seed integer) -> void
-- oid: 58194  kind: FUNCTION  category: debug

CREATE OR REPLACE FUNCTION dune.debug_set_farm_seed(in_new_coriolis_seed integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
	UPDATE world_farm_reset_seed SET world_reset_seed = in_new_coriolis_seed WHERE onerow_id = TRUE;

	UPDATE world_map_reset_seed SET world_reset_seed = in_new_coriolis_seed;
	INSERT INTO world_map_reset_seed SELECT map, in_new_coriolis_seed FROM world_partition GROUP BY map
		ON CONFLICT(map) DO
		UPDATE SET world_reset_seed = in_new_coriolis_seed;

	UPDATE world_partition_reset_seed SET world_reset_seed = in_new_coriolis_seed;
	INSERT INTO world_partition_reset_seed SELECT partition_id, in_new_coriolis_seed FROM world_partition GROUP BY partition_id
		ON CONFLICT(partition_id) DO
		UPDATE SET world_reset_seed = in_new_coriolis_seed;
end
$function$
