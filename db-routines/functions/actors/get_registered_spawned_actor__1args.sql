-- get_registered_spawned_actor(in_spawner_id bigint) -> SETOF bigint
-- oid: 58348  kind: FUNCTION  category: actors

CREATE OR REPLACE FUNCTION dune.get_registered_spawned_actor(in_spawner_id bigint)
 RETURNS SETOF bigint
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
	SELECT actor_id FROM actor_spawner_actors WHERE spawner_id = in_spawner_id;
END; $function$
