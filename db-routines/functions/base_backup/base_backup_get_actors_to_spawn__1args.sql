-- base_backup_get_actors_to_spawn(in_base_backup_id bigint) -> SETOF dune.actorspawninfo
-- oid: 58144  kind: FUNCTION  category: base_backup

CREATE OR REPLACE FUNCTION dune.base_backup_get_actors_to_spawn(in_base_backup_id bigint)
 RETURNS SETOF dune.actorspawninfo
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
		SELECT a.id, a.class as class_name, a.transform, a.partition_id, a.dimension_index
        FROM actors as a
        WHERE a.id IN (
            SELECT actor_id FROM base_backup_linked_actors as bbla WHERE bbla.id = in_base_backup_id
        );
END
$function$
