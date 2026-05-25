-- update_traveling_actor_dependencies(in_dep dune.traveldependency[]) -> void
-- oid: 58640  kind: FUNCTION  category: actors

CREATE OR REPLACE FUNCTION dune.update_traveling_actor_dependencies(in_dep dune.traveldependency[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
	with valid_ids as (
		with d as (select * from unnest(in_dep))
		select d.id from d where d.id is not null
		union
		select d.parent_id from d where d.parent_id is not null
	),
	valid_ids_plus_dep as (
		select * from valid_ids
		union
		select tap.id from travel_actor_parent as tap where tap.parent_id in (select * from valid_ids)
	),
	-- remove valid ids and connected dependencies from actor_state
	delete_actor_state_ids AS (
		delete from actor_state as acs
		where acs.actor_id in (select * from valid_ids_plus_dep) and acs.state = 'Travel'
	)
	-- remove valid ids and connected dependencies from any other dependency tree
	delete from travel_actor_parent
	where id in (select * from valid_ids_plus_dep);
	
	-- add/update dependencies with valid parent and child ids
	with valid_dep as (
		select a1.id as id, a2.id as parent_id, d.is_instigator
		from unnest(in_dep) d
		left join actors as a1
			on d.id = a1.id
		left join actors as a2
			on d.parent_id = a2.id
		where
				a1.id is not null
			and a2.id is not null
	)
	insert into travel_actor_parent (id, parent_id, is_instigator)
		select * from valid_dep
	on conflict (id) do update set
		"parent_id" = excluded.parent_id,
		"is_instigator" = excluded.is_instigator;
end
$function$
