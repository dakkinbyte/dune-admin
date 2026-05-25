-- igwo_delete_world_partitions(in_partition_ids bigint[]) -> void
-- oid: 58369  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.igwo_delete_world_partitions(in_partition_ids bigint[])
 RETURNS void
 LANGUAGE sql
AS $function$
	delete from world_partition where partition_id = any(in_partition_ids);
$function$
