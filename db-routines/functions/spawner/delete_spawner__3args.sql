-- delete_spawner(in_map text, in_name text, in_dimension_index integer) -> void
-- oid: 58230  kind: FUNCTION  category: spawner

CREATE OR REPLACE FUNCTION dune.delete_spawner(in_map text, in_name text, in_dimension_index integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    DELETE FROM actor_spawners WHERE map = in_map AND name = in_name AND dimension_index = in_dimension_index;
END
$function$
