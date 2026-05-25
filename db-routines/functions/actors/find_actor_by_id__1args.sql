-- find_actor_by_id(in_id bigint) -> dune.actorspawninfo
-- oid: 58263  kind: FUNCTION  category: actors

CREATE OR REPLACE FUNCTION dune.find_actor_by_id(in_id bigint)
 RETURNS dune.actorspawninfo
 LANGUAGE plpgsql
AS $function$
begin
	return (select (id, class, transform, partition_id, dimension_index)::ActorSpawnInfo
		FROM actors WHERE actors.id = in_id
		LIMIT 1);
end
$function$
