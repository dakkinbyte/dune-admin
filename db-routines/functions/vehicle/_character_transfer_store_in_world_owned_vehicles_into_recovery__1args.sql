-- _character_transfer_store_in_world_owned_vehicles_into_recovery(in_player_id bigint) -> void
-- oid: 58109  kind: FUNCTION  category: vehicle

CREATE OR REPLACE FUNCTION dune._character_transfer_store_in_world_owned_vehicles_into_recovery(in_player_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    to_store RECORD;
BEGIN
	-- remove any vehicles in 'Travel' state, so that they get re-added as recovered vehicles
	DELETE FROM actor_state ast
		WHERE ast.state = 'Travel'
		AND ast.actor_id IN (
			SELECT v.id
			FROM actors a
				INNER JOIN vehicles v ON a.id = v.id
				INNER JOIN permission_actor p ON a.id = p.actor_id
				INNER JOIN permission_actor_rank r ON p.actor_id = r.permission_actor_id
			WHERE r.player_id = in_player_id
			AND r.rank = 1::smallint
		);

    FOR to_store IN
		SELECT v.id AS vehicle_id
		FROM actors a
			INNER JOIN vehicles v ON a.id = v.id
			INNER JOIN permission_actor p ON a.id = p.actor_id
			INNER JOIN permission_actor_rank r ON p.actor_id = r.permission_actor_id
		WHERE r.player_id = in_player_id
		AND r.rank = 1::smallint
		AND NOT EXISTS
		(
			SELECT 1 FROM actor_state
			WHERE actor_state.actor_id = v.id
			AND actor_state.state IS DISTINCT FROM 'Default'
		)
	LOOP
		-- note: storing hardcoded chassis durability because its not available from pure database :(
		-- this will only be shown incorrectly in UI though, the spawned vehicle will get the correct value
        PERFORM store_recovered_vehicle(to_store.vehicle_id, 1.0, 'None', true);

		-- we delete the permissions for this vehicle so that they don't get exported and cause duplicated key failures
        -- when the player tries to recover their vehicle on the target battlegroup
		-- note: the server will destroy the vehicle as soon as it gets the pg_notify emitted from the store_recovered_vehicle call above, so this would happen regardless
		DELETE FROM permission_actor pa WHERE pa.actor_id = to_store.vehicle_id;
    END LOOP;
END
$function$
