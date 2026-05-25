-- permission_set_access_level(in_actor_id bigint, in_access_level smallint) -> void
-- oid: 58491  kind: FUNCTION  category: permission

CREATE OR REPLACE FUNCTION dune.permission_set_access_level(in_actor_id bigint, in_access_level smallint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	UPDATE permission_actor SET access_level = in_access_level WHERE permission_actor.actor_id = in_actor_id;

     PERFORM pg_notify('permission_notify_channel', format('set_access_level#{"ActorId" : %s , "AccessLevel" : %s}', in_actor_id, in_access_level));
END
$function$
