-- _character_transfer_data_filter(id text, removed text[], VARIADIC refs dune._charactertransferdatafilterref[]) -> dune._charactertransferdatafilter
-- oid: 58097  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune._character_transfer_data_filter(id text, removed text[], VARIADIC refs dune._charactertransferdatafilterref[] DEFAULT '{}'::dune._charactertransferdatafilterref[])
 RETURNS dune._charactertransferdatafilter
 LANGUAGE sql
 IMMUTABLE
AS $function$
	select (id, removed, refs)::_CharacterTransferDataFilter;
$function$
