-- _character_transfer_top_level_import(in_kind dune._charactertransferentrykind, data jsonb, in_id bigint) -> jsonb
-- oid: 58111  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune._character_transfer_top_level_import(in_kind dune._charactertransferentrykind, data jsonb, in_id bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
declare
    v_ref_transfer_id BigInt;
	v_ref_id BigInt;
    v_ref _CharacterTransferDataFilterRef;
	v_filter _CharacterTransferDataFilter;
begin
	v_filter := _character_transfer_get_filter(in_kind);

	if (v_filter).id is null then
		if in_id is not null then
			raise exception 'sbGM2$ - Transfer logic error: not-null in_id for secondary kind: %, data: %', in_kind, data;
		end if;
	else
		if in_id is null then
			raise exception 'sb8V2$ - Transfer logic error: null in_id for primary kind: %, data: %', in_kind, data;
		end if;
		data := data || jsonb_build_object((v_filter).id, in_id);
	end if;

    foreach v_ref in array (v_filter).refs loop
        v_ref_transfer_id := (data->>((v_ref).key))::BigInt;
        if v_ref_transfer_id is null then
			if (v_ref).required then
	            raise exception 'sb2C2$ - Missing reference % in import of kind %: %', (v_ref).key, in_kind, data;
			else
				continue;
			end if;
        end if;
		v_ref_id := (select to_jsonb(id) from pg_temp.export_data where kind=(v_ref).kind and transfer_id=v_ref_transfer_id);
		if v_ref_id is null then
			raise exception 'sb3W3$ - Unknown reference %s with transfer id % in import for kind %, reference id %: %', (v_ref).key, v_ref_transfer_id, in_kind, v_ref_id, data;
		end if;
        data := jsonb_set(data, array[(v_ref).key], to_jsonb(v_ref_id));
    end loop;
    return data;
end
$function$
