-- base_backup_get_available_backups(in_player_id bigint) -> TABLE(id bigint, base_backup_name text, totem_id bigint, totem_buildable_type text, landclaim_original_global_location real[], base_backup_map text)
-- oid: 58145  kind: FUNCTION  category: base_backup

CREATE OR REPLACE FUNCTION dune.base_backup_get_available_backups(in_player_id bigint)
 RETURNS TABLE(id bigint, base_backup_name text, totem_id bigint, totem_buildable_type text, landclaim_original_global_location real[], base_backup_map text)
 LANGUAGE plpgsql
AS $function$
begin
    RETURN QUERY
    SELECT
        bb.id,
        bb.base_backup_name,
        t.id AS totem_id,
        p.building_type,
        t.landclaim_original_global_location,
        a.map
    FROM base_backups bb
        JOIN base_backup_linked_actors bbla ON bbla.id = bb.id
        JOIN totems t ON bbla.actor_id = t.id
        JOIN actors a ON a.id = t.id
        JOIN placeables p ON p.id = a.id
    WHERE bb.player_id = in_player_id;
END
$function$
