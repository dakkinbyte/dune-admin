-- set_character_import_state(in_fls_id text, in_state dune.transferimportstate) -> void
-- oid: 58590  kind: FUNCTION  category: character_mod

CREATE OR REPLACE FUNCTION dune.set_character_import_state(in_fls_id text, in_state dune.transferimportstate)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	INSERT INTO character_transfer_imports (fls_id, last_update, transfer_state)
	VALUES (in_fls_id, now(), in_state)
	ON CONFLICT (fls_id) DO UPDATE
	SET last_update = now(),
		transfer_state = EXCLUDED.transfer_state;
END;
$function$
