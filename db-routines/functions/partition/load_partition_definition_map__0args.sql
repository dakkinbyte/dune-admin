-- load_partition_definition_map() -> TABLE(out_partition_id bigint, out_server_id text, out_partition_definition jsonb, out_dimension_index integer, out_blocked boolean, out_label text, out_map text)
-- oid: 58459  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.load_partition_definition_map()
 RETURNS TABLE(out_partition_id bigint, out_server_id text, out_partition_definition jsonb, out_dimension_index integer, out_blocked boolean, out_label text, out_map text)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY
	SELECT wp.partition_id, active_server_ids.server_id AS server_id, wp.partition_definition,
		   wp.dimension_index, wp.blocked, wp.label, wp.map
	FROM world_partition as wp
	LEFT JOIN active_server_ids
	ON active_server_ids.server_id = wp.server_id;
END; $function$
