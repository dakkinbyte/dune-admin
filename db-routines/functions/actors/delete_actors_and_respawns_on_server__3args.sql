-- delete_actors_and_respawns_on_server(in_server_info dune.serverinfo, in_vehicle_classes_spawned_on_map text[], in_allow_vehicle_recovery boolean) -> void
-- oid: 58201  kind: FUNCTION  category: actors

CREATE OR REPLACE FUNCTION dune.delete_actors_and_respawns_on_server(in_server_info dune.serverinfo, in_vehicle_classes_spawned_on_map text[], in_allow_vehicle_recovery boolean)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    WITH actors_to_delete AS (
	    SELECT a.id
        FROM actors a
        LEFT JOIN actor_state s ON a.id = s.actor_id
	    WHERE owner_account_id IS NULL
	    AND s.state IS DISTINCT FROM 'Travel'
	    AND s.state IS DISTINCT FROM 'VehicleBackup'
	    AND s.state IS DISTINCT FROM 'VehicleRecovery'
	    AND server_info_match(a, in_server_info)
        AND (
            -- Actors that are not vehicles should always be deleted
            NOT EXISTS (SELECT 1 FROM vehicles v WHERE v.id = a.id)
            -- Only vehicles that are allowed to be spawned on this map should be deleted
            OR in_vehicle_classes_spawned_on_map IS NULL -- If the list is NULL all vehicles are allowed
            OR a.class = ANY(in_vehicle_classes_spawned_on_map) -- Vehicle type is explicitly allowed on this map
        )
	    ORDER BY a.id FOR UPDATE OF a
    ),
    vehicles_to_recover AS (
        SELECT COALESCE(ARRAY_AGG(v.id), ARRAY[]::BIGINT[]) AS ids FROM actors_to_delete a JOIN vehicles v ON (a.id = v.id)
        WHERE in_allow_vehicle_recovery
    ),
    recovered_vehicles AS (
        SELECT ids, store_recovered_vehicles_wiped_before_spawn(ids) FROM vehicles_to_recover
    )
    DELETE FROM actors a USING recovered_vehicles rv
    WHERE a.id = ANY(SELECT id FROM actors_to_delete)
    AND NOT a.id = ANY(rv.ids);

	with
		deleted_ids as (
			DELETE from player_respawn_locations
				WHERE map = in_server_info.map AND dimension = in_server_info.dimension_index
				returning id
		)
		update player_state set pending_respawn_location_id=null
			where pending_respawn_location_id in (select * from deleted_ids);
END
$function$
