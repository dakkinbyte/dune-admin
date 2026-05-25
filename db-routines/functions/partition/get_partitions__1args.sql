-- get_partitions(in_map text) -> SETOF bigint
-- oid: 58324  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.get_partitions(in_map text)
 RETURNS SETOF bigint
 LANGUAGE plpgsql
AS $function$
begin
	SELECT partition_id FROM world_partition where map = in_map order by partition_id ASC;
end
$function$
