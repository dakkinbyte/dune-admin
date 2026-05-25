-- admin_get_partitions() -> TABLE(out_partition_id bigint, out_server_id text, out_partition_definition jsonb, out_dimension_index integer, out_blocked boolean, out_label text, out_map text)
-- oid: 58135  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.admin_get_partitions()
 RETURNS TABLE(out_partition_id bigint, out_server_id text, out_partition_definition jsonb, out_dimension_index integer, out_blocked boolean, out_label text, out_map text)
 LANGUAGE sql
AS $function$
	select * from load_partition_definition_map();
$function$
