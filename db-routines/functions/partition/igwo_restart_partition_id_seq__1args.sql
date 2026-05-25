-- igwo_restart_partition_id_seq(in_restart_with bigint) -> void
-- oid: 58377  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.igwo_restart_partition_id_seq(in_restart_with bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
	-- Use execute to substitute the numeric parameter into the alter sequence command
	execute format('alter sequence world_partition_partition_id_seq restart with %s', in_restart_with);
end;
$function$
