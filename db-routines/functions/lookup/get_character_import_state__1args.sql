-- get_character_import_state(in_fls_id text) -> dune.transferimportstate
-- oid: 58292  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_character_import_state(in_fls_id text)
 RETURNS dune.transferimportstate
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_state TransferImportState;
BEGIN
	SELECT transfer_state INTO v_state FROM character_transfer_imports WHERE fls_id = in_fls_id;
	RETURN v_state;
END;
$function$
