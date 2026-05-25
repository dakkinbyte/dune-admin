-- get_player_owned_vehicles_data(in_player_id bigint, in_account_id bigint) -> TABLE(out_actor_id bigint, out_name text, out_class text, out_map text, out_partition_id bigint, out_dimension integer, out_transform dune.transform, out_actor_state text)
-- oid: 58342  kind: FUNCTION  category: vehicle

CREATE OR REPLACE FUNCTION dune.get_player_owned_vehicles_data(in_player_id bigint, in_account_id bigint)
 RETURNS TABLE(out_actor_id bigint, out_name text, out_class text, out_map text, out_partition_id bigint, out_dimension integer, out_transform dune.transform, out_actor_state text)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY WITH owned_actors AS(
		SELECT (entry).actor_id, (entry).actor_name FROM get_permission_for_player_actors(in_player_id, 1::smallint) -- 1:owner
			WHERE (entry).actor_type = 2 -- 2:vehicles
		UNION SELECT vehicle_id, vehicle_name FROM recovered_vehicles -- note: recovered vehicles are removed from permission actors
			WHERE account_id = in_account_id
	) SELECT owned_actors.actor_id, actor_name, class, map, partition_id, dimension_index, transform, (actor_state).state::text
		FROM owned_actors LEFT JOIN actors ON actors.id = owned_actors.actor_id LEFT JOIN actor_state ON actor_state.actor_id = owned_actors.actor_id;
END
$function$
