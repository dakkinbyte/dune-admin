-- base_backup_save_all_totems_from_player_owner(in_player_id bigint) -> TABLE(base_backup_id bigint)
-- oid: 58153  kind: FUNCTION  category: base_backup

CREATE OR REPLACE FUNCTION dune.base_backup_save_all_totems_from_player_owner(in_player_id bigint)
 RETURNS TABLE(base_backup_id bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
        SELECT base_backup_save_from_totem(in_player_id, totem_id)
        FROM base_backup_find_totems_from_player_owner(in_player_id);
END;
$function$
