-- _character_transfer_create_data_table() -> void
-- oid: 58096  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune._character_transfer_create_data_table()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
	if not exists (
		select 1 from pg_catalog.pg_tables
		where schemaname=(select nspname from pg_catalog.pg_namespace where oid=pg_my_temp_schema())
		and tablename = 'export_data'
	) then
	    create temporary table if not exists pg_temp.export_data (
	        "id" BigInt DEFAULT NULL,
	        "transfer_id" BigSerial PRIMARY KEY NOT NULL,
	        "kind" _CharacterTransferEntryKind NOT NULL,
	        "data" JsonB NOT NULL
	    ) on commit drop;
		create index on pg_temp.export_data("id");
		create index on pg_temp.export_data("kind");
	end if;
	alter sequence pg_temp.export_data_transfer_id_seq restart with 1;
	truncate pg_temp.export_data;
end
$function$
