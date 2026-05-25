-- _character_transfer_top_level_export(in_kind dune._charactertransferentrykind, data jsonb) -> jsonb
-- oid: 58110  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune._character_transfer_top_level_export(in_kind dune._charactertransferentrykind, data jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
declare
    v_id BigInt;
	v_transfer_id BigInt;
    v_ref _CharacterTransferDataFilterRef;
	v_filter _CharacterTransferDataFilter;
begin
	v_filter := _character_transfer_get_filter(in_kind);
	data := data - (v_filter).removed;
	if (v_filter).id is not null then
		data := data - (v_filter).id;
	end if;
    foreach v_ref in array (v_filter).refs loop
        v_id := (data->>((v_ref).key))::BigInt;

        if v_id is null then
			if (v_ref).required then
	            raise exception 'sbP23$ - Required reference % not found in %', v_ref, data;
			else
				continue;
			end if;
        end if;

		v_transfer_id := (select transfer_id from pg_temp.export_data where kind=(v_ref).kind and id=v_id);
		if v_transfer_id is null then
			raise exception 'sbJG2$ - Id % in % not mapped into transfer id of kind %. Id exists as kind: %',
				v_id, data, (v_ref).kind, (select kind from pg_temp.export_data where id=v_id);
		end if;

        data := jsonb_set(data, array[(v_ref).key], to_jsonb(v_transfer_id));
    end loop;
    return data;
end
$function$
