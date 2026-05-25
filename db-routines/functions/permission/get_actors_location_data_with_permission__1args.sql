-- get_actors_location_data_with_permission(in_actor_ids bigint[]) -> SETOF dune.actorpermissionlocationdata
-- oid: 58272  kind: FUNCTION  category: permission

CREATE OR REPLACE FUNCTION dune.get_actors_location_data_with_permission(in_actor_ids bigint[])
 RETURNS SETOF dune.actorpermissionlocationdata
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY
	SELECT actors.id, actors.partition_id, actors.map, actors.dimension_index, actors.transform
	FROM actors
	WHERE actors.id = ANY(in_actor_ids);
END
$function$
