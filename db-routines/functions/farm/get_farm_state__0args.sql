-- get_farm_state() -> TABLE(server_id text, farm_id text, outgoing_s2s_connections integer, incoming_s2s_connections integer, connected_players integer, igw_addr inet, igw_port integer, game_addr inet, game_port integer, ready boolean, alive boolean, map text, revision integer)
-- oid: 58305  kind: FUNCTION  category: farm

CREATE OR REPLACE FUNCTION dune.get_farm_state()
 RETURNS TABLE(server_id text, farm_id text, outgoing_s2s_connections integer, incoming_s2s_connections integer, connected_players integer, igw_addr inet, igw_port integer, game_addr inet, game_port integer, ready boolean, alive boolean, map text, revision integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
BEGIN
	RETURN QUERY SELECT fs.server_id, fs.farm_id, fs.outgoing_s2s_connections, fs.incoming_s2s_connections, fs.connected_players, fs.igw_addr, fs.igw_port, fs.game_addr, fs.game_port, fs.ready, fs.alive, fs.map, fs.revision FROM farm_state as fs
		JOIN active_server_ids USING(server_id);
END
$function$
