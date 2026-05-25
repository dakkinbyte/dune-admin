-- store_recovered_vehicle(in_vehicle_id bigint, in_chassis_durability real, in_customization_id text, in_is_migration boolean) -> void
-- oid: 58599  kind: FUNCTION  category: vehicle

CREATE OR REPLACE FUNCTION dune.store_recovered_vehicle(in_vehicle_id bigint, in_chassis_durability real, in_customization_id text, in_is_migration boolean DEFAULT false)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    owner_id BIGINT;
	player_id BIGINT;
	vehicle_class TEXT;
	vehicle_name TEXT;
BEGIN
    -- Lock the recovered_vehicles table exclusively to prevent race conditions.
    LOCK TABLE recovered_vehicles IN EXCLUSIVE MODE;
 
     -- Check if the vehicle already belongs to an actor state
    PERFORM 1 FROM actor_state WHERE actor_id = in_vehicle_id;
    IF FOUND THEN
        RAISE EXCEPTION 'Trying to store recovered vehicle % that already has an actor state.', in_vehicle_id;
    END IF;
 
    -- Check if the vehicle is already in recovered_vehicles.
    PERFORM 1 FROM recovered_vehicles WHERE vehicle_id = in_vehicle_id;
    IF FOUND THEN
        RAISE EXCEPTION 'Vehicle % is already recovered.', in_vehicle_id;
    END IF;
 
    -- Check if the vehicle exists in the actors table.
    SELECT class INTO vehicle_class
	FROM actors 
	WHERE id = in_vehicle_id
	LIMIT 1;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Vehicle % does not exist in actors.', in_vehicle_id;
    END IF;
 
	-- get the vehicles owner account id
	SELECT a.owner_account_id, r.player_id, p.actor_name INTO owner_id, player_id, vehicle_name
	FROM actors a
	INNER JOIN permission_actor_rank r ON r.player_id = a.id
	INNER JOIN permission_actor p ON p.actor_id = r.permission_actor_id
	WHERE r.permission_actor_id = in_vehicle_id
	AND r.rank = 1::smallint
	LIMIT 1;
	
	IF NOT FOUND THEN
		RAISE EXCEPTION 'No account_id found for vehicle: %', in_vehicle_id;
	END IF;
	
    -- Insert the vehicle into recovered_vehicles.
    INSERT INTO recovered_vehicles(account_id, vehicle_id, chassis_durability, vehicle_name, customization_id, migrated) 
	VALUES (owner_id, in_vehicle_id, in_chassis_durability, vehicle_name, in_customization_id, in_is_migration);
    RAISE INFO 'Inserted vehicle % into recovered_vehicles for account %.', in_vehicle_id, owner_id;
 
    -- Mark the actor as belonging to the vehicle recovery tool
    INSERT INTO actor_state("actor_id", "state") VALUES(in_vehicle_id, 'VehicleRecovery');
    RAISE INFO 'Inserted vehicle % into actor_state with VehicleRecovery state', in_vehicle_id;
    
    PERFORM pg_notify('vehicle_recovery_notify_channel', FORMAT('stored#{"PlayerId":%s, "VehicleId":%s, "VehicleClass":"%s", "VehicleName":"%s", "VehicleCustomizationId":"%s", "TimeStored":"%s", "ChassisDurability":%s, "bIsMigrated":%s}', player_id, in_vehicle_id, vehicle_class, vehicle_name, in_customization_id, NOW()  AT TIME ZONE 'UTC', in_chassis_durability, CASE WHEN in_is_migration THEN 'true' ELSE 'false' END) );
 
END;
$function$
