-- save_building_blueprint_copy(in_building_item_id bigint, in_building_blueprint_id bigint, in_building_blueprint_building_data dune.buildingblueprintpiecesaveitemcontainer[], in_building_blueprint_placeable_data dune.buildingblueprintplaceablesaveitemcontainer[], in_building_blueprint_pentashield_data dune.buildingblueprintpentashielditem[]) -> bigint
-- oid: 58544  kind: FUNCTION  category: building_blueprint

CREATE OR REPLACE FUNCTION dune.save_building_blueprint_copy(in_building_item_id bigint, in_building_blueprint_id bigint, in_building_blueprint_building_data dune.buildingblueprintpiecesaveitemcontainer[], in_building_blueprint_placeable_data dune.buildingblueprintplaceablesaveitemcontainer[], in_building_blueprint_pentashield_data dune.buildingblueprintpentashielditem[])
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	return_id BIGINT;
BEGIN
	IF in_building_blueprint_id != 0 THEN
		DELETE FROM building_blueprints WHERE id = in_building_blueprint_id;
    END IF;

    INSERT INTO building_blueprints(id, item_id, player_id, building_blueprint_map)
        VALUES(DEFAULT, in_building_item_id, NULL, '') RETURNING id INTO return_id;

 -- All Building Pieces
    INSERT INTO building_blueprint_instances(building_blueprint_id, instance_id, building_type, transform, provides_stability, health, hologram)
    SELECT
        return_id,
        piece_data.instance_id,
        container_data.building_type,
        piece_data.transform,
        piece_data.provides_stability,
        piece_data.health,
        True
    FROM
        unnest(in_building_blueprint_building_data) AS container_data
        CROSS JOIN LATERAL unnest(container_data.building_pieces) AS piece_data;

-- All Placeables
    INSERT INTO building_blueprint_placeables(building_blueprint_id, placeable_id, building_type, transform, hologram)
    SELECT
        return_id,
        placeable_data.placeable_id,
        container_data.building_type,
        placeable_data.transform,
        True
    FROM
        unnest(in_building_blueprint_placeable_data) AS container_data
        CROSS JOIN LATERAL unnest(container_data.placeables) AS placeable_data;

-- Pentashields
    INSERT INTO building_blueprint_pentashields("building_blueprint_id", "placeable_id", "scale")
    SELECT return_id as building_blueprint_id, placeable_id, scale FROM unnest(in_building_blueprint_pentashield_data);

    RETURN return_id;
END
$function$
