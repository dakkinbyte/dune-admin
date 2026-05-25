-- base_backup_finish_placing(in_base_backup_id bigint) -> void
-- oid: 58143  kind: FUNCTION  category: base_backup

CREATE OR REPLACE FUNCTION dune.base_backup_finish_placing(in_base_backup_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    WITH base_info AS (
        SELECT
            bb.id AS base_backup_id,
            a.partition_id,
            a.dimension_index,
            a.map
        FROM
            base_backups bb
            JOIN actors a on bb.player_id = a.id
        WHERE
            bb.id = in_base_backup_id
    )
    UPDATE actors
    SET
        partition_id = base_info.partition_id,
        dimension_index = base_info.dimension_index,
        map = base_info.map
    FROM
        base_backup_linked_actors bbl
        JOIN base_info ON bbl.id = base_info.base_backup_id
    WHERE
        actors.id = bbl.actor_id;

    DELETE FROM actor_state a
        WHERE actor_id = ANY(
            SELECT actor_id
            FROM base_backup_linked_actors bbla
            WHERE bbla.id = in_base_backup_id
        );

    DELETE FROM base_backups
        WHERE id = in_base_backup_id;
END
$function$
