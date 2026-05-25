-- get_all_online_or_recently_disconnected_player_online_state() -> SETOF dune.playeronlinestateentry
-- oid: 58276  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_all_online_or_recently_disconnected_player_online_state()
 RETURNS SETOF dune.playeronlinestateentry
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY SELECT actors.id, player_state.character_name, (actors.map, actors.partition_id, actors.dimension_index)::ServerInfo, (player_state.last_avatar_activity AT TIME ZONE 'UTC')::TIMESTAMP, player_state.online_status
	FROM actors
	JOIN player_state ON player_state.player_controller_id = actors.id
	WHERE (player_state.online_status = 'Online' 
		or player_state.last_avatar_activity > NOW() - INTERVAL '1 minutes' );
END
$function$
