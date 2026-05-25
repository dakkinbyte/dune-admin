-- igwo_get_partition_id_seq_last_value() -> bigint
-- oid: 58370  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.igwo_get_partition_id_seq_last_value()
 RETURNS bigint
 LANGUAGE sql
AS $function$
	select last_value from world_partition_partition_id_seq;
$function$
