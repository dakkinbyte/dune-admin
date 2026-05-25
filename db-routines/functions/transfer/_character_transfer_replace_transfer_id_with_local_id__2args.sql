-- _character_transfer_replace_transfer_id_with_local_id(data text, path text) -> text
-- oid: 58107  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune._character_transfer_replace_transfer_id_with_local_id(data text, path text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
declare
	v_kind _CharacterTransferEntryKind;
	v_id BigInt;
	v_transfer_id BigInt;
begin
	if substring(data from 6 for 1) != '@' then
		raise exception 'sbFM3$ - Invalid transfer id % at %: expected @ separator', data, path;
	end if;

	v_kind := substring(data from 3 for 3)::_CharacterTransferEntryKind;

	v_transfer_id := (substring(data from 7))::BigInt;
	if v_transfer_id = 0 then
		return format('!!%s#0', v_kind::text);
	end if;

	v_id := (select id from pg_temp.export_data where transfer_id=v_transfer_id and kind=v_kind);
	if v_id is null then
		raise exception 'sbQ64$ - Transfer id % at % was not imported', data, path;
	end if;

	return format('!!%s#%s', v_kind::text, v_id::text);
end
$function$
