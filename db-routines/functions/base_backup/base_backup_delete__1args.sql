-- base_backup_delete(in_base_backup_id bigint) -> void
-- oid: 58141  kind: FUNCTION  category: base_backup

CREATE OR REPLACE FUNCTION dune.base_backup_delete(in_base_backup_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    actors_to_destroy BIGINT[];
BEGIN
    DELETE FROM actors a WHERE id = ANY(
        SELECT actor_id
        FROM base_backup_linked_actors bbla
        WHERE bbla.id = in_base_backup_id
    );

    DELETE FROM base_backups WHERE id = in_base_backup_id;
END
$function$
