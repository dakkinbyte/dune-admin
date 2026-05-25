-- _character_transfer_replace_local_id_with_transfer_id(data text, path text) -> text
-- oid: 58105  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune._character_transfer_replace_local_id_with_transfer_id(data text, path text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
declare
	v_kind _CharacterTransferEntryKind;
	v_raw_kind Text;
	v_id BigInt;
	v_transfer_id BigInt;
begin
	v_raw_kind = substring(data from 3 for 3);
	begin
		v_kind := v_raw_kind::_CharacterTransferEntryKind;
	exception
		when invalid_text_representation then
			raise exception 'sbPH2$ - Invalid transfer id in data "%" at "%", unknown kind: %', data, path, v_raw_kind;
	end;

	v_id := (substring(data from 7))::BigInt;
	if v_id = 0 then
		return format('!!%s@0', v_kind::text);
	end if;

	if v_id < 0 and v_id >= -2147483648 then
		v_id := v_id + 4294967296;
	end if;


	v_transfer_id := (select transfer_id from pg_temp.export_data where id=v_id and kind=v_kind);
	if v_transfer_id is null then
		if _character_transfer_property_not_exported_is_expected(path) then
			return format('!!%s@0', v_kind::text);
		else
			raise exception 'sbQ73$ - Id % by % was not exported', data, path;
		end if;
	end if;

	return format('!!%s@%s', v_kind::text, v_transfer_id::text);
end
$function$
