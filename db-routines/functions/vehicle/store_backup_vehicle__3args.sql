-- store_backup_vehicle(in_vehicle_id bigint, in_account_id bigint, in_customization_id text) -> void
-- oid: 58598  kind: FUNCTION  category: vehicle

CREATE OR REPLACE FUNCTION dune.store_backup_vehicle(in_vehicle_id bigint, in_account_id bigint, in_customization_id text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Lock the backup_vehicles table exclusively to prevent race conditions.
    LOCK TABLE backup_vehicles IN EXCLUSIVE MODE;
 
     -- Check if the vehicle already belongs to an actor state
    PERFORM 1 FROM actor_state WHERE actor_id = in_vehicle_id;
    IF FOUND THEN
        RAISE EXCEPTION 'Trying to backup vehicle % that already has an actor state.', in_vehicle_id;
    END IF;
 
    -- Check if the vehicle is already in backup_vehicles.
    PERFORM 1 FROM backup_vehicles WHERE vehicle_id = in_vehicle_id;
    IF FOUND THEN
        RAISE EXCEPTION 'Vehicle % is already stored as a backup.', in_vehicle_id;
    END IF;
 
    -- Check if the vehicle exists in the actors table.
    PERFORM 1 FROM actors WHERE id = in_vehicle_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Vehicle % does not exist in actors.', in_vehicle_id;
    END IF;
 
    -- Insert the vehicle into backup_vehicles.
    INSERT INTO backup_vehicles (account_id, vehicle_id, customization_id) 
	VALUES (in_account_id, in_vehicle_id, in_customization_id);
    RAISE INFO 'Inserted vehicle % into backup_vehicles for account %.', in_vehicle_id, in_account_id;
 
    -- Mark the actor as belonging to the vehicle backup tool
    INSERT INTO actor_state("actor_id", "state") VALUES(in_vehicle_id, 'VehicleBackup');
    RAISE INFO 'Inserted vehicle % into actor_state with VehicleBackup state', in_vehicle_id;
    
    PERFORM verify_item_dup_backup_tool(in_account_id, in_vehicle_id, 'item_dup_on_store_vbt');
 
END;
$function$
