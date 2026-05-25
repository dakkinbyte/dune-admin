-- record_logoff_persistence_end_time(in_player_pawn_id bigint, in_logoff_persistence_end_time timestamp without time zone) -> void
-- oid: 58504  kind: FUNCTION  category: player_persistence

CREATE OR REPLACE FUNCTION dune.record_logoff_persistence_end_time(in_player_pawn_id bigint, in_logoff_persistence_end_time timestamp without time zone)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE encrypted_player_state
    SET logoff_persistence_end_time = in_logoff_persistence_end_time
    WHERE player_pawn_id = in_player_pawn_id;
END
$function$
