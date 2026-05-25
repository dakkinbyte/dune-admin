-- get_permission_for_actor(in_actor_id bigint) -> dune.actorpermissioncombineddata
-- oid: 58327  kind: FUNCTION  category: permission

CREATE OR REPLACE FUNCTION dune.get_permission_for_actor(in_actor_id bigint)
 RETURNS dune.actorpermissioncombineddata
 LANGUAGE plpgsql
AS $function$
BEGIN
	return (select get_permission_for_actors(array[in_actor_id]) limit 1);
END
$function$
