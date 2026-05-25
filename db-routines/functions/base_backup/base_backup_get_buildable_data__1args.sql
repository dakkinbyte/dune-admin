-- base_backup_get_buildable_data(in_base_backup_id bigint) -> TABLE(buildable_type text, total_count integer)
-- oid: 58146  kind: FUNCTION  category: base_backup

CREATE OR REPLACE FUNCTION dune.base_backup_get_buildable_data(in_base_backup_id bigint)
 RETURNS TABLE(buildable_type text, total_count integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT t.buildable_type, SUM(t.cnt)::INT AS total_count
    FROM (
        SELECT bi.building_type AS buildable_type, COUNT(*) AS cnt
        FROM base_backup_linked_actors bla
        JOIN building_instances bi ON bla.actor_id = bi.building_id
        WHERE
            bla.id = in_base_backup_id AND
            (bi.building_flags IS NULL OR (bi.building_flags & (1 << 2) = 0 AND bi.building_flags & (1 << 7) = 0)) -- flag 2 and 7 not enabled, which relates to holograms and extensions
        GROUP BY bi.building_type

        UNION ALL

        SELECT p.building_type AS buildable_type, COUNT(*) AS cnt
        FROM base_backup_linked_actors bla
        JOIN placeables p ON bla.actor_id = p.id
        WHERE bla.id = in_base_backup_id AND p.is_hologram = FALSE
        GROUP BY p.building_type
    ) t
    GROUP BY t.buildable_type;
END
$function$
