-- _character_transfer_data_table_load(entries jsonb) -> void
-- oid: 58098  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune._character_transfer_data_table_load(entries jsonb)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
	with parsed as (
		select
			(entry->>'id')::BigInt as transfer_id,
			(entry->>'kind')::_CharacterTransferEntryKind as kind,
			(entry->'data') as data
		from jsonb_array_elements(entries) as entry
	)
	insert into pg_temp.export_data("id", "transfer_id", "kind", "data")
		select _character_transfer_allocate_id(kind, data) as id, transfer_id, kind, data
		from parsed;
end
$function$
