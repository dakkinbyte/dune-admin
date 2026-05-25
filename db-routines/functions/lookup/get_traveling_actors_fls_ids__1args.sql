-- get_traveling_actors_fls_ids(in_actor_id bigint) -> TABLE(out_id text)
-- oid: 58359  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_traveling_actors_fls_ids(in_actor_id bigint)
 RETURNS TABLE(out_id text)
 LANGUAGE plpgsql
AS $function$
begin
	return query
	select a.user
	from get_traveling_actor_ids(in_actor_id) as t
	inner join player_state as ps
		on t.id = ps.player_pawn_id
	inner join accounts as a
		on a.id = ps.account_id;
end
$function$
