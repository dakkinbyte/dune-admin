-- load_dimension_index(in_map text, in_partition_id bigint) -> integer
-- oid: 58452  kind: FUNCTION  category: misc

CREATE OR REPLACE FUNCTION dune.load_dimension_index(in_map text, in_partition_id bigint)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN (SELECT dimension_index from world_partition where map = in_map and partition_id = in_partition_id limit 1);
END; $function$
