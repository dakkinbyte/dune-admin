-- permission_set_name(in_actor_id bigint, in_name text) -> void
-- oid: 58492  kind: FUNCTION  category: permission

CREATE OR REPLACE FUNCTION dune.permission_set_name(in_actor_id bigint, in_name text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	UPDATE permission_actor SET actor_name = in_name WHERE permission_actor.actor_id = in_actor_id;

	UPDATE markers SET marker =
	(
		(marker).marker_type,
		(marker).x,
		(marker).y,
		(marker).z,
		(marker).payload_type
	),
	payload = jsonb_set(payload, '{TotemName}', to_jsonb(in_name) , false)
	WHERE marker_hash_id = in_actor_id;

    PERFORM pg_notify('permission_notify_channel', format('set_name#{"ActorId" : %s , "Name" : "%s"}', in_actor_id, in_name));
END
$function$
