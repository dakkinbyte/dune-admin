-- get_permission_actors_for_server(in_server_info dune.serverinfo) -> SETOF dune.actorpermissioncombineddata
-- oid: 58326  kind: FUNCTION  category: permission

CREATE OR REPLACE FUNCTION dune.get_permission_actors_for_server(in_server_info dune.serverinfo)
 RETURNS SETOF dune.actorpermissioncombineddata
 LANGUAGE plpgsql
AS $function$
BEGIN
	return query
		with ids as (
			select array_agg(actors.id) as ids
				from permission_actor join actors on actors.id = permission_actor.actor_id
				where server_info_match(actors, in_server_info) and actors.owner_account_id is null
		)
		select permissions.* from ids, get_permission_for_actors(ids.ids) as permissions;
END
$function$
