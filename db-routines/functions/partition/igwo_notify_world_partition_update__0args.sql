-- igwo_notify_world_partition_update() -> void
-- oid: 58376  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.igwo_notify_world_partition_update()
 RETURNS void
 LANGUAGE sql
AS $function$
	notify world_partition_update;
$function$
