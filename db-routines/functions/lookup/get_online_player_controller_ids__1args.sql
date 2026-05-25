-- get_online_player_controller_ids(in_map text) -> SETOF bigint
-- oid: 58321  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_online_player_controller_ids(in_map text)
 RETURNS SETOF bigint
 LANGUAGE plpgsql
AS $function$
BEGIN
    return query SELECT DISTINCT ps.player_controller_id
        FROM player_state ps
        JOIN actors a ON (a.id = ps.player_controller_id)
        WHERE ps.online_status = 'Online' AND a.map = in_map;
END;
$function$
