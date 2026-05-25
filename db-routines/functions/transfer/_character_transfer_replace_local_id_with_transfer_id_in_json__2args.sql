-- _character_transfer_replace_local_id_with_transfer_id_in_json(data jsonb, path text) -> jsonb
-- oid: 58106  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune._character_transfer_replace_local_id_with_transfer_id_in_json(data jsonb, path text)
 RETURNS jsonb
 LANGUAGE sql
AS $function$
	select case
		when data is json array then
			(select coalesce(jsonb_agg(_character_transfer_replace_local_id_with_transfer_id_in_json(
				element, path || '.*'
			)), '[]'::jsonb) from jsonb_array_elements(data) as element)
		when data is json object then
			(select coalesce(jsonb_object_agg(key, _character_transfer_replace_local_id_with_transfer_id_in_json(
				value, path || '.' || key
			)), '{}'::jsonb) from jsonb_each(data))
		when data is json scalar and jsonb_typeof(data) = 'string' and (data #>> '{}') like '!!___#%' then
			(select to_jsonb(_character_transfer_replace_local_id_with_transfer_id(
				data #>> '{}', path
			)))
		else
			data
	end;
$function$
