-- base_backup_get_totem_id(backup_id bigint) -> bigint
-- oid: 58150  kind: FUNCTION  category: base_backup

CREATE OR REPLACE FUNCTION dune.base_backup_get_totem_id(backup_id bigint)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
    result BIGINT;
BEGIN
    SELECT t.id
        INTO result
        FROM totems t
            JOIN base_backup_linked_actors bbla ON t.id = bbla.actor_id
        WHERE bbla.id = backup_id
        LIMIT 1;

    IF result IS NULL THEN
        RAISE EXCEPTION 'No totem found for base_backup id %', backup_id;
    END IF;

    RETURN result;
END;
$function$
