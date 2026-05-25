-- get_all_unresolved_character_imports() -> TABLE(flsid text, importstate dune.transferimportstate, lastupdatetime timestamp with time zone)
-- oid: 58284  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_all_unresolved_character_imports()
 RETURNS TABLE(flsid text, importstate dune.transferimportstate, lastupdatetime timestamp with time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY SELECT ti.fls_id, ti.transfer_state, ti.last_update
	FROM character_transfer_imports ti;
END;
$function$
