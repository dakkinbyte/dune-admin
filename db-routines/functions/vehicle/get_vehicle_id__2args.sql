-- get_vehicle_id(in_actor_id bigint, in_class text) -> bigint
-- oid: 58364  kind: FUNCTION  category: vehicle

CREATE OR REPLACE FUNCTION dune.get_vehicle_id(in_actor_id bigint, in_class text)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	vehicle_id BIGINT;
BEGIN
	SELECT INTO vehicle_id id FROM vehicles WHERE "id" = in_actor_id;
	IF vehicle_id IS NULL THEN
		SELECT assign_actor_id(in_class) id INTO vehicle_id;
		INSERT INTO vehicles("id") VALUES(vehicle_id);
	END IF;
	RETURN vehicle_id;
END
$function$
