-- register_spawned_actor(in_spawner_id bigint, in_actor_id bigint) -> void
-- oid: 58511  kind: FUNCTION  category: actors

CREATE OR REPLACE FUNCTION dune.register_spawned_actor(in_spawner_id bigint, in_actor_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	INSERT INTO actor_spawner_actors(spawner_id, actor_id) VALUES(in_spawner_id, in_actor_id);
END $function$
