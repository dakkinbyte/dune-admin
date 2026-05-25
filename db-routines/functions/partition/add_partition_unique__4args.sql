-- add_partition_unique(in_map text, in_definition jsonb, in_dimension bigint, in_label text) -> bigint
-- oid: 58127  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.add_partition_unique(in_map text, in_definition jsonb, in_dimension bigint, in_label text DEFAULT NULL::text)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_partition_id bigint;
BEGIN
	-- Don't use a constraint right now, this is only a dev-only helper function.
	-- We could add a constraint, but would need to check the performance of constraint on the jsonb field.
	insert into world_partition (map, partition_definition, dimension_index, label)
		select in_map, in_definition, in_dimension, in_label
	where not exists (
		select 1 from world_partition where map = in_map and partition_definition = in_definition and dimension_index = in_dimension
	) returning partition_id into v_partition_id;
	return v_partition_id;
END;
$function$
