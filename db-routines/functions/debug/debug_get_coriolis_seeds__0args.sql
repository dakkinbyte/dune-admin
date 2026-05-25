-- debug_get_coriolis_seeds() -> TABLE(farm_seed integer, map_names text[], map_seeds integer[], partitions_ids bigint[], partitions_map text[], partitions_seeds integer[])
-- oid: 58190  kind: FUNCTION  category: debug

CREATE OR REPLACE FUNCTION dune.debug_get_coriolis_seeds()
 RETURNS TABLE(farm_seed integer, map_names text[], map_seeds integer[], partitions_ids bigint[], partitions_map text[], partitions_seeds integer[])
 LANGUAGE plpgsql
AS $function$
begin
	RETURN QUERY
		WITH
			map_seeds as (
				SELECT array_agg(map_name) as map_name, array_agg(seed) as seed
				FROM (
						SELECT COALESCE(map_seed.map, partition.map) AS map_name, COALESCE(map_seed.world_reset_seed, -1) AS seed
						FROM world_map_reset_seed AS map_seed FULL JOIN world_partition as partition ON map_seed.map = partition.map
						GROUP BY map_seed.map, partition.map, map_seed.world_reset_seed
						ORDER BY map_name ASC
					) as maps_temp

			),
			partitions_seeds as (
				SELECT array_agg(partition_id) as partition_id, array_agg(map_name) as map_name, array_agg(seed) as seed
				FROM (
						SELECT partition.partition_id as partition_id, partition.map as map_name, COALESCE(partition_seed.world_reset_seed, -1) AS seed
						FROM world_partition_reset_seed AS partition_seed FULL JOIN world_partition as partition ON partition_seed.partition_id = partition.partition_id
						GROUP BY partition.map, partition.partition_id, partition_seed.world_reset_seed
						ORDER BY partition.partition_id ASC
					) as partitions_temp
			)
		SELECT
			COALESCE(world_reset_seed, -1),
			COALESCE(map_seeds.map_name, array[]::TEXT[]),
			COALESCE(map_seeds.seed, array[]::Integer[]),
			COALESCE(partitions_seeds.partition_id, array[]::BigInt[]),
			COALESCE(partitions_seeds.map_name, array[]::TEXT[]),
			COALESCE(partitions_seeds.seed, array[]::Integer[])
		FROM
			world_farm_reset_seed,
			map_seeds,
			partitions_seeds;
end
$function$
