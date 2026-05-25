-- store_recovered_vehicles_wiped_before_spawn(in_vehicle_ids bigint[], in_delete_items boolean) -> void
-- oid: 58600  kind: FUNCTION  category: vehicle

CREATE OR REPLACE FUNCTION dune.store_recovered_vehicles_wiped_before_spawn(in_vehicle_ids bigint[], in_delete_items boolean DEFAULT true)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	to_store RECORD;
BEGIN
	FOR to_store IN
		SELECT v.id AS vehicle_id, a.properties -> (regexp_replace("class", '^.*\.', '')) ->> 'm_CustomizationId' AS customization_id
		FROM actors a
		INNER JOIN vehicles v ON a.id = v.id
		INNER JOIN permission_actor p ON a.id = p.actor_id
		INNER JOIN permission_actor_rank r ON p.actor_id = r.permission_actor_id
		WHERE v.id = ANY(in_vehicle_ids)
		AND r.rank = 1::smallint
		AND NOT EXISTS
		(
			SELECT 1 FROM actor_state
			WHERE actor_state.actor_id = v.id
			AND actor_state.state IS DISTINCT FROM 'Default'
		)
	LOOP
		-- remove all items in all inventories of that vehicle
		if in_delete_items then
			PERFORM delete_items_from_actor(to_store.vehicle_id);
		end if;
	
		-- note: storing hardcoded chassis durability because its not available from pure database :(
		-- this will only be shown incorrectly in UI though, the spawned vehicle will get the correct value
		PERFORM store_recovered_vehicle(to_store.vehicle_id, 0.25, to_store.customization_id);

		-- remove permissions so the stored vehicles don't count towards the vehicle limit (the owner is preserved in the store function above)
		PERFORM permission_actor_destroy(to_store.vehicle_id);
	END LOOP;
END
$function$
