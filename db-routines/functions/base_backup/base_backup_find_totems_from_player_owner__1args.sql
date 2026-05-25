-- base_backup_find_totems_from_player_owner(in_player_id bigint) -> TABLE(totem_id bigint)
-- oid: 58142  kind: FUNCTION  category: base_backup

CREATE OR REPLACE FUNCTION dune.base_backup_find_totems_from_player_owner(in_player_id bigint)
 RETURNS TABLE(totem_id bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
        SELECT t.id
        FROM totems t
            JOIN permission_actor_rank par ON par.permission_actor_id = t.id
            WHERE par.player_id = in_player_id AND par.rank = 1;
END;
$function$
