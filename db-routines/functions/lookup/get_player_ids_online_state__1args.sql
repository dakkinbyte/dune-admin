-- get_player_ids_online_state(in_player_ids bigint[]) -> SETOF dune.playeronlinestateentry
-- oid: 58336  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_player_ids_online_state(in_player_ids bigint[])
 RETURNS SETOF dune.playeronlinestateentry
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY SELECT actors.id, player_state.character_name, (actors.map, actors.partition_id, actors.dimension_index)::ServerInfo, (player_state.last_avatar_activity AT TIME ZONE 'UTC')::TIMESTAMP, player_state.online_status
	FROM actors
	JOIN player_state ON player_state.player_controller_id = actors.id
	WHERE actors.id = ANY(in_player_ids);
END
$function$
