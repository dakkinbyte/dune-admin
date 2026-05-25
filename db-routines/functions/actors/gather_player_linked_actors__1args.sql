-- gather_player_linked_actors(in_player_pawn_id bigint) -> SETOF dune.actorspawninfo
-- oid: 58267  kind: FUNCTION  category: actors

CREATE OR REPLACE FUNCTION dune.gather_player_linked_actors(in_player_pawn_id bigint)
 RETURNS SETOF dune.actorspawninfo
 LANGUAGE plpgsql
AS $function$
begin
	return query
		select actors.id, actors.class as class_name, actors.transform, actors.partition_id, actors.dimension_index
		from actors
		left join actor_state on actor_state.actor_id = actors.id
		where actors.id in (select id from get_traveling_non_player_actor_ids(in_player_pawn_id)) and actor_state.state = 'Travel' and actors.owner_account_id is null
		order by actors.id;
end
$function$
