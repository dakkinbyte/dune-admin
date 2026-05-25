-- base_backup_get_data(in_base_backup_id bigint) -> dune.getbasebackupdata
-- oid: 58147  kind: FUNCTION  category: base_backup

CREATE OR REPLACE FUNCTION dune.base_backup_get_data(in_base_backup_id bigint)
 RETURNS dune.getbasebackupdata
 LANGUAGE plpgsql
AS $function$
DECLARE
    base_backup_name TEXT;
    totem_data BaseBackupTotemData;
    buildings_array BaseBackupBuildingItem[];
    placeables_array BaseBackupPlaceableItem[];
BEGIN

    SELECT bb.base_backup_name
        INTO base_backup_name
        FROM base_backups bb
        WHERE bb.id = in_base_backup_id;

    totem_data := base_backup_get_totem_data(in_base_backup_id);

    -- building pieces
    SELECT array_agg((bi.building_id, bi.instance_id, bi.building_type, bi.transform, bi.building_flags)::BaseBackupBuildingItem)
		into buildings_array
		FROM
            building_instances bi
            JOIN base_backup_linked_actors bbla ON bi.building_id = bbla.actor_id
		WHERE bbla.id = in_base_backup_id;

    -- placeables
    SELECT array_agg((p.building_type, a.transform)::BaseBackupPlaceableItem)
		into placeables_array
		FROM
            placeables p
            JOIN actors a ON p.id = a.id
            JOIN base_backup_linked_actors bbla ON a.id = bbla.actor_id
		WHERE
            bbla.id = in_base_backup_id;

    return ROW(base_backup_name, totem_data, buildings_array, placeables_array)::GetBaseBackupData;
END
$function$
