-- character_migration_import(in_data jsonb, in_fls_id text, in_character_name text) -> bigint
-- oid: 58159  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune.character_migration_import(in_data jsonb, in_fls_id text, in_character_name text)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
BEGIN
	-- Add any migration-specific actions here before the import call
	RETURN character_transfer_import(in_data, in_fls_id, in_character_name);
END
$function$
