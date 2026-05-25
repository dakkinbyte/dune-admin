-- assign_actor_id(in_class text) -> bigint
-- oid: 58140  kind: FUNCTION  category: actors

CREATE OR REPLACE FUNCTION dune.assign_actor_id(in_class text)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
    new_id BIGINT;
BEGIN
	INSERT INTO actors(id) VALUES(DEFAULT) RETURNING id INTO new_id;
	PERFORM add_actor_audit(new_id, in_class);

	RETURN new_id;
END
$function$
