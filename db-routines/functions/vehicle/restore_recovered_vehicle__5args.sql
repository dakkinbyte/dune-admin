-- restore_recovered_vehicle(in_account_id bigint, in_vehicle_id bigint, in_server_info dune.serverinfo, in_transform dune.transform, in_restore_time_limit integer) -> void
-- oid: 58535  kind: FUNCTION  category: vehicle

CREATE OR REPLACE FUNCTION dune.restore_recovered_vehicle(in_account_id bigint, in_vehicle_id bigint, in_server_info dune.serverinfo, in_transform dune.transform, in_restore_time_limit integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    found_vehicle_id BIGINT;
	found_vehicle_name TEXT;
	found_player_id BIGINT;
BEGIN
    -- Retrieve a recovered vehicle for the provided account.
    SELECT vehicle_id, vehicle_name INTO found_vehicle_id, found_vehicle_name 
    FROM recovered_vehicles
    WHERE account_id = in_account_id AND vehicle_id = in_vehicle_id
	-- 60s leeway in favor of player in case they try to restore last second
	AND (migrated = TRUE OR time_stored > NOW() - (in_restore_time_limit + 60) * INTERVAL '1 second')
    LIMIT 1;  -- In case more than one is stored.

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No recovered vehicle found for account_id: % and vehicle_id: %', in_account_id, in_vehicle_id;
    END IF;

    -- Only restore vehicle if the actor state is VehicleRecovery
    PERFORM 1 FROM actor_state WHERE actor_id = found_vehicle_id AND state = 'VehicleRecovery';
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Trying to restore vehicle % that does not belong to vehicle recovery feature.', found_vehicle_id;
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

	-- permissions use the player controllers id, so we need to get that from the account id
	SELECT player_controller_id INTO found_player_id FROM player_state WHERE account_id = in_account_id LIMIT 1;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'No player_controller_id found for account: %', in_account_id;
	END IF;
	
	-- restore default permissions
	INSERT INTO	permission_actor("actor_id", "actor_name", "actor_type", "access_level", "is_child")
	VALUES(found_vehicle_id, found_vehicle_name, 2, 3, false);

	INSERT INTO permission_actor_rank("permission_actor_id", "player_id", "rank")
	VALUES(found_vehicle_id, found_player_id, 1);

    -- Remove the restored vehicle from recovered_vehicles.
    DELETE FROM recovered_vehicles WHERE vehicle_id = found_vehicle_id;
    RAISE INFO 'Deleted recovery record for vehicle %.', found_vehicle_id;

    -- There is no need to keep the actor state in the table anymore since the vehicle recovery was successful data wise
    DELETE FROM actor_state WHERE actor_id = found_vehicle_id;
    RAISE INFO 'Deleted actor state for vehicle %.', found_vehicle_id;

    --PERFORM verify_item_dup_backup_tool(in_account_id, found_vehicle_id, 'item_dup_on_restore_vbt');

END;
$function$
