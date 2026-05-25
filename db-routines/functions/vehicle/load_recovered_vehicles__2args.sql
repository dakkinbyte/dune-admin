-- load_recovered_vehicles(in_account_id bigint, in_restore_time_limit integer) -> TABLE(out_vehicle_id bigint, out_class text, out_name text, out_time_stored timestamp without time zone, out_chassis_durability real, out_customization_id text, out_migrated boolean)
-- oid: 58461  kind: FUNCTION  category: vehicle

CREATE OR REPLACE FUNCTION dune.load_recovered_vehicles(in_account_id bigint, in_restore_time_limit integer)
 RETURNS TABLE(out_vehicle_id bigint, out_class text, out_name text, out_time_stored timestamp without time zone, out_chassis_durability real, out_customization_id text, out_migrated boolean)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY
		SELECT vehicle_id, class, vehicle_name, time_stored AT TIME ZONE 'UTC', chassis_durability, customization_id, migrated 
		FROM actors 
		JOIN recovered_vehicles on id = vehicle_id 
		WHERE account_id = in_account_id
		AND (migrated = TRUE OR time_stored > NOW() - in_restore_time_limit * INTERVAL '1 second')
		AND EXISTS (SELECT 1 FROM actor_state WHERE actor_state.actor_id = id AND actor_state.state = 'VehicleRecovery')
		ORDER BY time_stored DESC;
END
$function$
