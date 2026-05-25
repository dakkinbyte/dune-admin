-- _character_transfer_data_table_save() -> jsonb
-- oid: 58099  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune._character_transfer_data_table_save()
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
begin
	return (select jsonb_agg(jsonb_build_object('id', transfer_id, 'kind', kind, 'data', data)) from pg_temp.export_data);
end
$function$
