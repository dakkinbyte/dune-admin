-- base_backup_get_totem_data(in_base_backup_id bigint) -> dune.basebackuptotemdata
-- oid: 58148  kind: FUNCTION  category: base_backup

CREATE OR REPLACE FUNCTION dune.base_backup_get_totem_data(in_base_backup_id bigint)
 RETURNS dune.basebackuptotemdata
 LANGUAGE plpgsql
AS $function$
DECLARE
    totem_id BIGINT;
    result BaseBackupTotemData;
BEGIN
    SELECT t.id
        INTO totem_id
        FROM totems t JOIN base_backup_linked_actors bbla ON t.id = bbla.actor_id
        WHERE bbla.id = in_base_backup_id
        LIMIT 1;

    IF totem_id IS NULL THEN
        RAISE EXCEPTION 'No totem found for base_backup id %', in_base_backup_id;
    END IF;

    result := base_backup_get_totem_data_from_totem_id(totem_id);

    RETURN result;
END;
$function$
