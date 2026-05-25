-- coriolis_cleanup_partition(in_server_info dune.serverinfo, in_map_info dune.coriolismapinfo) -> void
-- oid: 58179  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.coriolis_cleanup_partition(in_server_info dune.serverinfo, in_map_info dune.coriolismapinfo)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	IF in_map_info.is_outside_shieldwall
	THEN
        PERFORM delete_actors_and_respawns_on_server(in_server_info, (in_map_info).vehicle_classes_spawned_on_map, TRUE);

		update player_state set life_state='DeadByCoriolis'
			from actors
			where player_state.player_pawn_id=actors.id AND server_info_match(actors, in_server_info) and
			not exists (SELECT 1 FROM actor_state WHERE actor_state.actor_id = player_state.player_pawn_id AND actor_state.state = 'Travel');

		-- Move players that died to Hagga Basin in their respective dimension and partition
		UPDATE actors
		SET
			map = 'HaggaBasin',
			dimension_index = player_state.return_dimension_index,
			partition_id = (
				SELECT world_partition.partition_id
				FROM world_partition
				WHERE player_state.return_dimension_index = world_partition.dimension_index AND world_partition.map = 'Survival_1'
			)
		FROM player_state
		WHERE
			(player_state.player_controller_id = actors.id OR player_state.player_pawn_id = actors.id OR player_state.player_state_id = actors.id) AND
			server_info_match(actors, in_server_info) AND
			NOT EXISTS (SELECT 1 FROM actor_state WHERE actor_state.actor_id = player_state.player_pawn_id AND actor_state.state = 'Travel');
	END IF;
END
$function$
