-- get_active_servers_for_gateway() -> TABLE(server_id text, map text, partition_id bigint, dimension_index integer, game_addr inet, game_port integer, revision integer)
-- oid: 58270  kind: FUNCTION  category: server
-- comment: Used by the gateway service to monitor for active servers.

CREATE OR REPLACE FUNCTION dune.get_active_servers_for_gateway()
 RETURNS TABLE(server_id text, map text, partition_id bigint, dimension_index integer, game_addr inet, game_port integer, revision integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
BEGIN
	-- If we have no partitions, assume dimension 0
	return query select fs.server_id, fs.map, wp.partition_id, coalesce(wp.dimension_index, 0), fs.game_addr, fs.game_port, fs.revision from active_server_ids as asi left join world_partition as wp on asi.server_id = wp.server_id join farm_state as fs on fs.server_id = asi.server_id;
END
$function$
