-- get_traveling_actor_ids(in_actor_id bigint, in_max_recursion_level integer) -> TABLE(id bigint, is_instigator boolean, level integer)
-- oid: 58358  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_traveling_actor_ids(in_actor_id bigint, in_max_recursion_level integer DEFAULT 5)
 RETURNS TABLE(id bigint, is_instigator boolean, level integer)
 LANGUAGE plpgsql
AS $function$
begin
	return query
	with recursive
		-- go down the dependency tree and gather all the parents
        p(id, lvl) AS (
				select a.id, 0
				from actors as a
				where (in_actor_id = a.id)
			union all
				select ap.parent_id, (p.lvl - 1)
				from p, travel_actor_parent as ap
				where (p.id = ap.id) and (p.lvl > -in_max_recursion_level)
		),
		-- find the most distant parent (root)
		r as (
			select * from p	order by p.lvl limit 1
		),
		-- go up the tree from the root and gather all the children
		t(id, ins, lvl) as (
				select r.id, true, 0 from r
			union all
				select ap.id, ap.is_instigator, (t.lvl + 1)
				from t, travel_actor_parent as ap
				where (t.id = ap.parent_id) and (t.lvl < 2 * in_max_recursion_level)
		)
	select * from t order by t.lvl, id;
end
$function$
