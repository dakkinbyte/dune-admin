-- igwo_next_partition_id_seq() -> bigint
-- oid: 58375  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.igwo_next_partition_id_seq()
 RETURNS bigint
 LANGUAGE sql
AS $function$
	select nextval('world_partition_partition_id_seq');
$function$
