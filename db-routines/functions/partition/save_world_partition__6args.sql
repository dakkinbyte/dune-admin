-- save_world_partition(in_map_name text, in_server_id text, in_dimension_index bigint, in_partition_definition jsonb, in_blocked boolean, in_label text) -> bigint
-- oid: 58575  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.save_world_partition(in_map_name text, in_server_id text, in_dimension_index bigint, in_partition_definition jsonb, in_blocked boolean DEFAULT false, in_label text DEFAULT NULL::text)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	partition_id BIGINT;
BEGIN
	LOCK TABLE world_partition; -- only one at a time, please
	INSERT INTO world_partition(partition_id, server_id, map, partition_definition, dimension_index, blocked, label) VALUES(DEFAULT, in_server_id, in_map_name, in_partition_definition, in_dimension_index, in_blocked, in_label)
		ON CONFLICT ("server_id", "map") DO UPDATE set partition_definition = in_partition_definition, blocked = in_blocked, label = in_label WHERE world_partition.server_id = in_server_id
		RETURNING world_partition.partition_id INTO partition_id;
	RETURN partition_id;
END
$function$
