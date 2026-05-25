-- permission_actor_destroy(in_actor_id bigint) -> void
-- oid: 58486  kind: FUNCTION  category: permission

CREATE OR REPLACE FUNCTION dune.permission_actor_destroy(in_actor_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM permission_actor_rank WHERE permission_actor_id = in_actor_id;
	DELETE FROM permission_actor WHERE actor_id = in_actor_id;
	-- Destroy map markers related with this actor
	DELETE FROM markers WHERE marker_hash_id = in_actor_id;
	DELETE FROM player_markers WHERE marker_hash_id = in_actor_id;

    PERFORM pg_notify('permission_notify_channel', format('destroy#{"ActorId" : %s}', in_actor_id));
END
$function$
