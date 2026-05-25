-- igwo_insert_world_partition(in_partition_id bigint, in_map text, in_partition_definition jsonb, in_dimension_index integer, in_partition_label text) -> bigint
-- oid: 58374  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.igwo_insert_world_partition(in_partition_id bigint, in_map text, in_partition_definition jsonb, in_dimension_index integer DEFAULT 0, in_partition_label text DEFAULT NULL::text)
 RETURNS bigint
 LANGUAGE sql
AS $function$
	insert into world_partition(partition_id, map, partition_definition, dimension_index, label)
	values (
		in_partition_id,
		in_map,
		in_partition_definition,
		in_dimension_index,
		coalesce(in_partition_label, determine_partition_label(in_map, in_dimension_index, null, false, in_partition_id)))
	returning partition_id;
$function$
