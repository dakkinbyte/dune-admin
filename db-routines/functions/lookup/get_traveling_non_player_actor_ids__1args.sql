-- get_traveling_non_player_actor_ids(in_actor_id bigint) -> TABLE(id bigint)
-- oid: 58360  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_traveling_non_player_actor_ids(in_actor_id bigint)
 RETURNS TABLE(id bigint)
 LANGUAGE plpgsql
AS $function$
begin
	return query
	select t.id
	from get_traveling_actor_ids(in_actor_id) as t
	left join player_state as ps
		on t.id = ps.player_pawn_id
	left join travel_actor_parent as ap
		on ap.id = in_actor_id
	where
			ps.player_pawn_id is null
		and ap.is_instigator is true
	order by t.level, t.id;
end
$function$
