-- reset_all_players_from_server_ids_grace_period_and_logoff_timer(in_server_id text, in_reset_time timestamp without time zone) -> void
-- oid: 58528  kind: FUNCTION  category: cleanup

CREATE OR REPLACE FUNCTION dune.reset_all_players_from_server_ids_grace_period_and_logoff_timer(in_server_id text, in_reset_time timestamp without time zone)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE encrypted_player_state SET reconnect_grace_period_end = in_reset_time WHERE server_id = in_server_id AND reconnect_grace_period_end > in_reset_time;
    UPDATE encrypted_player_state SET logoff_persistence_end_time = in_reset_time WHERE server_id = in_server_id AND logoff_persistence_end_time > in_reset_time;
END
$function$
