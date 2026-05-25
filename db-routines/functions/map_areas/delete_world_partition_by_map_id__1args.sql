-- delete_world_partition_by_map_id(in_map_id text) -> void
-- oid: 58232  kind: FUNCTION  category: map_areas

CREATE OR REPLACE FUNCTION dune.delete_world_partition_by_map_id(in_map_id text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM world_partition WHERE "map"=in_map_id;
END
$function$
