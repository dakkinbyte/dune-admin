-- get_partition_presets() -> SETOF text
-- oid: 58323  kind: FUNCTION  category: partition
-- comment: Adds a partition only if its unique. Not using constraints, as this is only a helper function.

CREATE OR REPLACE FUNCTION dune.get_partition_presets()
 RETURNS SETOF text
 LANGUAGE plpgsql
AS $function$
BEGIN
	return query SELECT routine_name::text as preset_function FROM information_schema.routines WHERE routine_type = 'FUNCTION' and routine_name ilike 'initialize_partitions_%';
END;
$function$
