-- get_traveling_actor_id_and_types(in_actor_id bigint) -> TABLE(id bigint, is_instigator boolean, is_player boolean, level integer)
-- oid: 58357  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_traveling_actor_id_and_types(in_actor_id bigint)
 RETURNS TABLE(id bigint, is_instigator boolean, is_player boolean, level integer)
 LANGUAGE plpgsql
AS $function$
begin
	return query
	select t.id, t.is_instigator, (ps.player_pawn_id is not null) as is_player, t.level
	from get_traveling_actor_ids(in_actor_id) as t
	left join player_state as ps
	on t.id = ps.player_pawn_id
	order by t.level, t.id;
end
$function$
