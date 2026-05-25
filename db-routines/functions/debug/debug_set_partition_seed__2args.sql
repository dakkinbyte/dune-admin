-- debug_set_partition_seed(in_partition_id bigint, in_new_coriolis_seed integer) -> void
-- oid: 58196  kind: FUNCTION  category: debug

CREATE OR REPLACE FUNCTION dune.debug_set_partition_seed(in_partition_id bigint, in_new_coriolis_seed integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
	INSERT INTO world_partition_reset_seed (partition_id, world_reset_seed) Values(in_server_info.partition_id, in_new_coriolis_seed)
		ON CONFLICT(partition_id) DO
		UPDATE SET world_reset_seed = in_new_coriolis_seed;
end
$function$
