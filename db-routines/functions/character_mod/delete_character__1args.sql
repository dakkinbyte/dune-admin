-- delete_character(in_actor_id bigint) -> void
-- oid: 58210  kind: FUNCTION  category: character_mod

CREATE OR REPLACE FUNCTION dune.delete_character(in_actor_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    DELETE FROM actors WHERE id = in_actor_id;
    DELETE FROM properties WHERE object_id = in_actor_id;
    DELETE FROM fgl_data WHERE object_id = in_actor_id;
    DELETE FROM actor_transform WHERE actor_id = in_actor_id;
END
$function$
