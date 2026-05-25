-- _character_transfer_get_patches_checksum() -> text
-- oid: 58102  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune._character_transfer_get_patches_checksum()
 RETURNS text
 LANGUAGE plpgsql
AS $function$
begin
	return (SELECT md5(coalesce(string_agg("name", ',' ORDER BY "name"), '')) FROM applied_patches);
end
$function$
