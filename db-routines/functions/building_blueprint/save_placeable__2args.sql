-- save_placeable(in_placeable_id bigint, in_data dune.placeablesavedata) -> void
-- oid: 58561  kind: FUNCTION  category: building_blueprint

CREATE OR REPLACE FUNCTION dune.save_placeable(in_placeable_id bigint, in_data dune.placeablesavedata)
 RETURNS void
 LANGUAGE sql
BEGIN ATOMIC
 INSERT INTO dune.placeables (id, owner_entity_id, health, building_type, has_hit_ground, has_buildable_support, is_hologram)
   VALUES (save_placeable.in_placeable_id, dune._placeable_validate_totem_owner_id((save_placeable.in_data).in_owner_entity_id), (save_placeable.in_data).in_health, (save_placeable.in_data).in_building_type, (save_placeable.in_data).in_has_hit_ground, (save_placeable.in_data).in_has_buildable_support, (save_placeable.in_data).in_is_hologram) ON CONFLICT(id) DO UPDATE SET owner_entity_id = excluded.owner_entity_id, health = excluded.health, building_type = excluded.building_type, has_hit_ground = excluded.has_hit_ground, has_buildable_support = excluded.has_buildable_support, is_hologram = excluded.is_hologram;
END
