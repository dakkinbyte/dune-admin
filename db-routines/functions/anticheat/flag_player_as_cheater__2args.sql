-- flag_player_as_cheater(in_account_id bigint, in_cheat_type dune.cheat_type_enum) -> void
-- oid: 58265  kind: FUNCTION  category: anticheat

CREATE OR REPLACE FUNCTION dune.flag_player_as_cheater(in_account_id bigint, in_cheat_type dune.cheat_type_enum)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_FLS_id TEXT;
BEGIN
    SELECT acc."user"
        INTO v_FLS_id
        FROM accounts acc
        WHERE acc.id = in_account_id
        LIMIT 1;

    PERFORM log_cheating(v_FLS_id, in_cheat_type);
END;
$function$
