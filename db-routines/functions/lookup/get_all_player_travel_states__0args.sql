-- get_all_player_travel_states() -> TABLE(fls_id text, login_target_dimension_index integer)
-- oid: 58282  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_all_player_travel_states()
 RETURNS TABLE(fls_id text, login_target_dimension_index integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
BEGIN
    RETURN query SELECT pts.fls_id, pts.login_target_dimension_index FROM player_travel_state AS pts;
END;
$function$
