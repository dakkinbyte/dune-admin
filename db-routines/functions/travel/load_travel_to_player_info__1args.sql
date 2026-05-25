-- load_travel_to_player_info(in_player_controller_id bigint) -> TABLE(map text, transform dune.transform, partition_id bigint, dimension_index integer)
-- oid: 58466  kind: FUNCTION  category: travel

CREATE OR REPLACE FUNCTION dune.load_travel_to_player_info(in_player_controller_id bigint)
 RETURNS TABLE(map text, transform dune.transform, partition_id bigint, dimension_index integer)
 LANGUAGE plpgsql
AS $function$
begin
	return query
	select actors.map, actors.transform, actors.partition_id, actors.dimension_index
	from player_state
	join actors on player_state.player_pawn_id = actors.id
	where player_state.player_controller_id = in_player_controller_id
	and player_state.online_status = 'Online';
end
$function$
