-- debug_set_map_seed(in_map text, in_new_coriolis_seed integer) -> void
-- oid: 58195  kind: FUNCTION  category: debug

CREATE OR REPLACE FUNCTION dune.debug_set_map_seed(in_map text, in_new_coriolis_seed integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
	INSERT INTO world_map_reset_seed (map, world_reset_seed) Values(in_server_info.map, in_new_coriolis_seed)
		ON CONFLICT(map) DO
		UPDATE SET world_reset_seed = in_new_coriolis_seed;

	UPDATE world_partition_reset_seed SET world_reset_seed = in_new_coriolis_seed WHERE map = in_map;
	INSERT INTO world_partition_reset_seed SELECT partition_id, in_new_coriolis_seed FROM world_partition WHERE map = in_map GROUP BY partition_id
		ON CONFLICT(partition_id) DO
		UPDATE SET world_reset_seed = in_new_coriolis_seed;
end
$function$
