-- _character_transfer_pre_export_validation(in_fls_id text) -> TABLE(out_acc_id bigint, out_funcom_id text, out_player_controller_id bigint, out_player_pawn_id bigint)
-- oid: 58103  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune._character_transfer_pre_export_validation(in_fls_id text)
 RETURNS TABLE(out_acc_id bigint, out_funcom_id text, out_player_controller_id bigint, out_player_pawn_id bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_acc_id BigInt;
    v_funcom_id Text;
	v_player_controller_id BigInt;
	v_player_pawn_id BigInt;
BEGIN
	if not (select is_player_offline(in_fls_id)) then
        raise exception 'sbRF3$ - player_online: Player % must be Offline', in_fls_id;
    end if;

	v_acc_id := (select id from accounts where "user" = in_fls_id);
    IF v_acc_id is null THEN
        RAISE EXCEPTION 'sbFV2$ - unknown_fls_id: FLS ID % not found', in_fls_id;
    END IF;

    v_funcom_id := (select funcom_id from accounts where "user" = in_fls_id);
    IF v_funcom_id is null THEN
        RAISE EXCEPTION 'sb9X3$ - missing_funcom_id: Player % does not have a funcomId', in_fls_id;
    END IF;

	select into v_player_controller_id, v_player_pawn_id
		player_controller_id, player_pawn_id from player_state where account_id=v_acc_id;
	if v_player_controller_id is null then
		raise exception 'sbH84$ - missing_controller: Player % does not have a controller', in_fls_id;
	end if;
	if v_player_pawn_id is null then
		raise exception 'sbHF3$ - missing_character: Player % does not have a character', in_fls_id;
	end if;

	return query select v_acc_id, v_funcom_id, v_player_controller_id, v_player_pawn_id;
END;
$function$
