-- _character_transfer_replace_transfer_id_with_local_id_in_json(data jsonb, path text) -> jsonb
-- oid: 58108  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune._character_transfer_replace_transfer_id_with_local_id_in_json(data jsonb, path text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
declare
	v_id_str Text;
begin
	if data is json array then
		return (
			select coalesce(jsonb_agg(_character_transfer_replace_transfer_id_with_local_id_in_json(
				element, path || '.*'
			)), '[]'::jsonb) from jsonb_array_elements(data) as element
		);
	end if;

	if data is json object then
		return (
			select coalesce(jsonb_object_agg(key, _character_transfer_replace_transfer_id_with_local_id_in_json(
				value, path || '.' || key
			)), '{}'::jsonb) from jsonb_each(data)
		);
	end if;

	if data is json scalar then
		if jsonb_typeof(data) = 'string' then
			v_id_str := (data #>> '{}');

			if v_id_str like '!!___#%' then
				raise exception 'sbJ34$ - Non-transfer id % is found at %', v_id_str, path;
			end if;

			if v_id_str like '!!___@%' then
				return (select to_jsonb(_character_transfer_replace_transfer_id_with_local_id(v_id_str, path)));
			end if;

			if v_id_str = '!!@0' then
				raise exception 'sb5G3$ - Transfer id missing kind marker at %: %', path, v_id_str;
			end if;
		end if;
	end if;

	return data;
end
$function$
