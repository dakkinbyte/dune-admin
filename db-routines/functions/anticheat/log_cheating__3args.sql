-- log_cheating(in_fls_id text, in_cheat_type dune.cheat_type_enum, in_event_time timestamp with time zone) -> void
-- oid: 58469  kind: FUNCTION  category: anticheat

CREATE OR REPLACE FUNCTION dune.log_cheating(in_fls_id text, in_cheat_type dune.cheat_type_enum, in_event_time timestamp with time zone DEFAULT now())
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN

    -- Insert into suspicious_be
    INSERT INTO cheater_tracking (
        event_time,
        fls_id,
        cheat_type
    ) VALUES (
        in_event_time,
        in_fls_id,
        in_cheat_type
    );
END;
$function$
