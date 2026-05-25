-- get_actor_server_info(in_id bigint) -> dune.serverinfo
-- oid: 58271  kind: FUNCTION  category: actors

CREATE OR REPLACE FUNCTION dune.get_actor_server_info(in_id bigint)
 RETURNS dune.serverinfo
 LANGUAGE plpgsql
AS $function$
begin
	return (select (map, partition_id, dimension_index)::ServerInfo from actors where id=in_id limit 1);
end
$function$
