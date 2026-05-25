-- character_migration_export(in_fls_id text) -> jsonb
-- oid: 58158  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune.character_migration_export(in_fls_id text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_player_controller_id BigInt;
BEGIN
	select out_player_controller_id
		into v_player_controller_id
	from _character_transfer_pre_export_validation(in_fls_id);

	perform _character_transfer_store_in_world_owned_vehicles_into_recovery(v_player_controller_id);
	perform base_backup_save_all_totems_from_player_owner(v_player_controller_id);
	-- Add any other migration-specific actions here before the export call

	return character_transfer_export(in_fls_id);
END;
$function$
