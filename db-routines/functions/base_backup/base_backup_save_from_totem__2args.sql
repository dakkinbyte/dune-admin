-- base_backup_save_from_totem(in_player_id bigint, totem_id bigint) -> bigint
-- oid: 58154  kind: FUNCTION  category: base_backup

CREATE OR REPLACE FUNCTION dune.base_backup_save_from_totem(in_player_id bigint, totem_id bigint)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
    totem_entity_id BIGINT;
    totem_name TEXT;
    building_pieces_to_link BaseBackupBuildingItem[];
    placeables_to_link BIGINT[];
    placeables_to_remove_totem_owner BIGINT[];
BEGIN
    SELECT entity_id INTO totem_entity_id
        FROM actor_fgl_entities
        WHERE actor_id = totem_id;

    SELECT COALESCE(actor_name, '') INTO totem_name
        FROM permission_actor
        WHERE actor_id = totem_id
        LIMIT 1;

    SELECT array_agg((bi.building_id, bi.instance_id, bi.building_type, bi.transform, bi.building_flags)::BaseBackupBuildingItem)
        INTO building_pieces_to_link
        FROM building_instances bi
        WHERE bi.owner_entity_id = totem_entity_id;

    SELECT array_agg(p.id)
        INTO placeables_to_link
        FROM placeables p
        WHERE (p.owner_entity_id = totem_entity_id AND p.has_buildable_support = TRUE) OR p.id = totem_id;

    SELECT array_agg(p.id)
        INTO placeables_to_remove_totem_owner
        FROM placeables p
        WHERE p.owner_entity_id = totem_entity_id AND p.has_buildable_support = FALSE AND p.id != totem_id;

    RETURN base_backup_save(
        in_player_id,
        totem_name,
        building_pieces_to_link,
        placeables_to_link,
        placeables_to_remove_totem_owner
    );
END;
$function$
