-- parties_get_exclusive_operation_lock() -> void
-- oid: 58483  kind: FUNCTION  category: misc

CREATE OR REPLACE FUNCTION dune.parties_get_exclusive_operation_lock()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	PERFORM pg_advisory_xact_lock(9457135);  -- Parties in leet :/
END;
$function$
