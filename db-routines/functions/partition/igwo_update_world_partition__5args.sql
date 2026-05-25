-- igwo_update_world_partition(in_map text, in_partition_definition jsonb, in_partition_id bigint, in_dimension_index integer, in_label text) -> void
-- oid: 58378  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.igwo_update_world_partition(in_map text, in_partition_definition jsonb, in_partition_id bigint, in_dimension_index integer, in_label text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE sql
AS $function$
	update world_partition
	set map = in_map,
		partition_definition = in_partition_definition,
		dimension_index = in_dimension_index,
		label = coalesce(in_label, label)
	where partition_id = in_partition_id;
$function$
