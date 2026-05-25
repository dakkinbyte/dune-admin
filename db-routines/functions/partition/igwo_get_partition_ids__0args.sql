-- igwo_get_partition_ids() -> SETOF bigint
-- oid: 58371  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.igwo_get_partition_ids()
 RETURNS SETOF bigint
 LANGUAGE sql
AS $function$
	select partition_id from world_partition order by partition_id asc;
$function$
