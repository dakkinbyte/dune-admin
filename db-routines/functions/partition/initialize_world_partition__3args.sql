-- initialize_world_partition(in_map_name text, in_num_servers integer, in_dimension_index integer) -> SETOF bigint
-- oid: 58389  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.initialize_world_partition(in_map_name text, in_num_servers integer, in_dimension_index integer DEFAULT 0)
 RETURNS SETOF bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
BEGIN
	return query
		with _cleanup as (
			DELETE FROM world_partition WHERE map = in_map_name and dimension_index = in_dimension_index
		)
		INSERT INTO world_partition (map, partition_definition, dimension_index, label)
			select in_map_name, format('{"type": "cell_index", "index": %s}', generate_series)::JSONB, in_dimension_index, in_map_name || '_' || in_dimension_index || '_' || generate_series
			from generate_series(0, in_num_servers - 1)
			returning partition_id;
END
$function$
