-- permission_actor_update_marker_location(in_actor_id bigint, in_location_x real, in_location_y real, in_location_z real) -> void
-- oid: 58489  kind: FUNCTION  category: permission

CREATE OR REPLACE FUNCTION dune.permission_actor_update_marker_location(in_actor_id bigint, in_location_x real, in_location_y real, in_location_z real)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	UPDATE markers SET marker =
	(
		(marker).marker_type,
		in_location_x,
		in_location_y,
		in_location_z,
		(marker).payload_type
	)
	WHERE marker_hash_id = in_actor_id;
END
$function$
