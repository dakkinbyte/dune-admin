-- get_online_player_controller_ids_on_farm() -> SETOF bigint
-- oid: 58322  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_online_player_controller_ids_on_farm()
 RETURNS SETOF bigint
 LANGUAGE plpgsql
AS $function$
BEGIN
    return query SELECT DISTINCT ps.player_controller_id
        FROM player_state ps
        JOIN actors a ON (a.id = ps.player_controller_id)
        WHERE ps.online_status = 'Online';
END;
$function$
