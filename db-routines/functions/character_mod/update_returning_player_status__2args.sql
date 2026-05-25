-- update_returning_player_status(in_user_id text, in_minimum_returning_player_time_seconds integer) -> void
-- oid: 58633  kind: FUNCTION  category: character_mod

CREATE OR REPLACE FUNCTION dune.update_returning_player_status(in_user_id text, in_minimum_returning_player_time_seconds integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    user_account_id BigInt;
    last_login_time TIMESTAMPTZ;
    last_award_time TIMESTAMPTZ;
BEGIN
    SELECT INTO user_account_id, last_login_time, last_award_time id, ps.last_login_time, ps.last_returning_player_awarded_time
    FROM accounts acc
	JOIN player_state ps ON ps.account_id = acc.id
    WHERE acc.user=in_user_id;

    IF user_account_id IS NOT NULL THEN
        IF last_award_time + INTERVAL '1 second' * in_minimum_returning_player_time_seconds > CURRENT_TIMESTAMP THEN
            UPDATE player_state SET last_returning_player_event_time=NULL WHERE account_id=user_account_id;
        ELSIF last_login_time + INTERVAL '1 second' * in_minimum_returning_player_time_seconds < CURRENT_TIMESTAMP THEN
            UPDATE player_state SET last_returning_player_event_time=now() WHERE account_id=user_account_id;
        END IF;
    END IF;
END
$function$
