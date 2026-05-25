-- igwo_get_server_details() -> TABLE(address text, server_id text, ready boolean, partition_id bigint, map text, dimension_index integer, label text)
-- oid: 58373  kind: FUNCTION  category: igwo

CREATE OR REPLACE FUNCTION dune.igwo_get_server_details()
 RETURNS TABLE(address text, server_id text, ready boolean, partition_id bigint, map text, dimension_index integer, label text)
 LANGUAGE sql
AS $function$
	select
		host(fs.igw_addr)||':'||fs.igw_port as address,
		fs.server_id,
		fs.ready,
		wp.partition_id,
		wp.map,
		wp.dimension_index,
		wp.label
	from get_farm_state() fs
	left join world_partition wp on wp.server_id = fs.server_id
	where fs.server_id is not null;
$function$
