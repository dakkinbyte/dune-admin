-- returning_player_award_given(in_account_id bigint) -> void
-- oid: 58537  kind: FUNCTION  category: character_mod

CREATE OR REPLACE FUNCTION dune.returning_player_award_given(in_account_id bigint)
 RETURNS void
 LANGUAGE sql
AS $function$
    UPDATE player_state SET last_returning_player_awarded_time=now(), last_returning_player_event_time=NULL WHERE account_id=in_account_id;
$function$
