-- igwo_get_partitions() -> TABLE(partition_id bigint, map text, dimension_index integer, label text, min_x double precision, min_y double precision, max_x double precision, max_y double precision)
-- oid: 58372  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.igwo_get_partitions()
 RETURNS TABLE(partition_id bigint, map text, dimension_index integer, label text, min_x double precision, min_y double precision, max_x double precision, max_y double precision)
 LANGUAGE sql
AS $function$
	SELECT
		partition_id,
		map,
		dimension_index,
		label,
		(partition_definition->'box'->>'min_x')::float8,
		(partition_definition->'box'->>'min_y')::float8,
		(partition_definition->'box'->>'max_x')::float8,
		(partition_definition->'box'->>'max_y')::float8
	FROM world_partition
	ORDER BY partition_id ASC;
$function$
