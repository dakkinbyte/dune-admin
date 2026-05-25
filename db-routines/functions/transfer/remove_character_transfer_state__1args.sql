-- remove_character_transfer_state(in_fls_id text) -> void
-- oid: 58516  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune.remove_character_transfer_state(in_fls_id text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM character_transfer_imports WHERE fls_id = in_fls_id;
END;
$function$
