-- restore_backup_vehicle(in_account_id bigint, in_server_info dune.serverinfo, in_transform dune.transform) -> bigint
-- oid: 58534  kind: FUNCTION  category: vehicle

CREATE OR REPLACE FUNCTION dune.restore_backup_vehicle(in_account_id bigint, in_server_info dune.serverinfo, in_transform dune.transform)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
    found_vehicle_id BIGINT;
BEGIN
    -- Retrieve a backup vehicle for the provided account.
    SELECT vehicle_id INTO found_vehicle_id
      FROM backup_vehicles
     WHERE account_id = in_account_id
     LIMIT 1;  -- In case more than one is stored.

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No backup vehicle found for account_id: %', in_account_id;
    END IF;

    -- Only restore vehicle if the actor state is vehicle backup
    PERFORM 1 FROM actor_state WHERE actor_id = found_vehicle_id AND state = 'VehicleBackup';
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Trying to restore vehicle % that does not belong to vehicle backup feature.', found_vehicle_id;
    END IF;

	-- Update the actors record to restore the vehicle.
    UPDATE actors
	SET map = in_server_info.map,
		partition_id = in_server_info.partition_id,
		dimension_index = in_server_info.dimension_index,
		transform = in_transform
	WHERE id = found_vehicle_id;
    IF NOT FOUND THEN
        RAISE WARNING 'No actor record found with id % during restore.', found_vehicle_id;
    END IF;

    -- Remove the restored vehicle from backup_vehicles.
    DELETE FROM backup_vehicles WHERE vehicle_id = found_vehicle_id;
    RAISE INFO 'Deleted backup record for vehicle %.', found_vehicle_id;

    -- There is no need to keep the actor state in the table anymore since the vehicle backup was successful data wise
    DELETE FROM actor_state WHERE actor_id = found_vehicle_id;
    RAISE INFO 'Deleted actor state for vehicle %.', found_vehicle_id;

    PERFORM verify_item_dup_backup_tool(in_account_id, found_vehicle_id, 'item_dup_on_restore_vbt');

    RETURN found_vehicle_id;
END;
$function$
