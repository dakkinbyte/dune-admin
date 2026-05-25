-- base_backup_get_totem_data_from_totem_id(in_totem_id bigint) -> dune.basebackuptotemdata
-- oid: 58149  kind: FUNCTION  category: base_backup

CREATE OR REPLACE FUNCTION dune.base_backup_get_totem_data_from_totem_id(in_totem_id bigint)
 RETURNS dune.basebackuptotemdata
 LANGUAGE plpgsql
AS $function$
DECLARE
    result BaseBackupTotemData;
BEGIN
    SELECT
        t.id,
        p.building_type,
        a.map,
        t.landclaim_original_global_location,
        t.landclaim_original_global_yaw_rotation,
        t.landclaim_vertical_level
    INTO
        result.totem_actor_id,
        result.totem_building_type,
        result.totem_map,
        result.landclaim_original_global_location,
        result.landclaim_original_global_yaw_rotation,
        result.landclaim_vertical_level
    FROM totems t
        JOIN placeables p ON p.id = t.id
        JOIN actors a ON a.id = t.id
    WHERE t.id = in_totem_id
    LIMIT 1;

    IF result.totem_actor_id IS NULL THEN
        RAISE EXCEPTION 'No totem found for totem_id %', in_totem_id;
    END IF;

    SELECT array_agg(ROW(grid_location_x, grid_location_y)::SMALLINTPOINT)
        INTO result.landclaim_grid
        FROM landclaim_segments s
        WHERE s.totem_id = result.totem_actor_id;

    RETURN result;
END;
$function$
