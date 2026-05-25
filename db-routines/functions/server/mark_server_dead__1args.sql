-- mark_server_dead(in_server_id text) -> void
-- oid: 58473  kind: FUNCTION  category: server

CREATE OR REPLACE FUNCTION dune.mark_server_dead(in_server_id text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	UPDATE farm_state SET alive = false WHERE server_id = in_server_id;
END $function$
