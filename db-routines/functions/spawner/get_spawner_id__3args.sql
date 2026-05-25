-- get_spawner_id(in_map text, in_name text, in_dimension_index integer) -> bigint
-- oid: 58352  kind: FUNCTION  category: spawner

CREATE OR REPLACE FUNCTION dune.get_spawner_id(in_map text, in_name text, in_dimension_index integer)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	spawner_id BIGINT;
BEGIN
    SELECT INTO spawner_id "id" FROM actor_spawners WHERE map = in_map AND name = in_name AND dimension_index = in_dimension_index;
    IF spawner_id IS NULL THEN
        INSERT INTO actor_spawners("map", "name", "dimension_index") VALUES(in_map, in_name, in_dimension_index) ON CONFLICT DO NOTHING RETURNING "id" INTO spawner_id;
        IF spawner_id IS NULL THEN
            SELECT INTO spawner_id "id" FROM actor_spawners WHERE map = in_map AND name = in_name AND dimension_index = in_dimension_index;
        END IF;
    END IF;
    RETURN spawner_id;
END $function$
