-- update_farm_state(in_server_id text, in_outgoing_s2s_connections integer, in_incoming_s2s_connections integer, in_connected_players integer, in_farm_id text, in_igw_addr inet, in_igw_port integer, in_ready boolean, in_alive boolean, in_game_addr inet, in_game_port integer, in_map text, in_revision integer) -> void
-- oid: 58620  kind: FUNCTION  category: farm

CREATE OR REPLACE FUNCTION dune.update_farm_state(in_server_id text, in_outgoing_s2s_connections integer, in_incoming_s2s_connections integer, in_connected_players integer, in_farm_id text, in_igw_addr inet, in_igw_port integer, in_ready boolean, in_alive boolean, in_game_addr inet, in_game_port integer, in_map text, in_revision integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	INSERT INTO farm_state
		(server_id, outgoing_s2s_connections, incoming_s2s_connections, connected_players, farm_id, igw_addr, igw_port, ready, alive, game_addr, game_port, map, revision)
	VALUES
		(in_server_id, in_outgoing_s2s_connections, in_incoming_s2s_connections, in_connected_players, in_farm_id, in_igw_addr, in_igw_port, in_ready, in_alive, in_game_addr, in_game_port, in_map, in_revision)
	ON CONFLICT(server_id) DO UPDATE SET
		outgoing_s2s_connections=in_outgoing_s2s_connections, incoming_s2s_connections=in_incoming_s2s_connections, connected_players=in_connected_players, farm_id=in_farm_id, igw_addr=in_igw_addr, igw_port=in_igw_port, ready=in_ready, alive=in_alive, game_addr=in_game_addr, game_port=in_game_port, map=in_map, revision=in_revision
	WHERE
		farm_state.server_id = in_server_id;
END
$function$
