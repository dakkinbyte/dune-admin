-- guilds_get_exclusive_operation_lock() -> void
-- oid: 58367  kind: FUNCTION  category: guild

CREATE OR REPLACE FUNCTION dune.guilds_get_exclusive_operation_lock()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    PERFORM pg_advisory_xact_lock(601145);  -- GUILDS in leet :/
END;
$function$
