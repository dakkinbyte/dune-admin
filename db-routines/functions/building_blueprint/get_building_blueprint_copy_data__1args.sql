-- get_building_blueprint_copy_data(in_building_blueprint_id bigint) -> dune.buildingblueprintgetcopydata
-- oid: 58289  kind: FUNCTION  category: building_blueprint

CREATE OR REPLACE FUNCTION dune.get_building_blueprint_copy_data(in_building_blueprint_id bigint)
 RETURNS dune.buildingblueprintgetcopydata
 LANGUAGE plpgsql
AS $function$
DECLARE
    buildings_array BuildingBlueprintItem[];
    placeables_array BuildingBlueprintPlaceableItem[];
    pentashields_array BuildingBlueprintPentashieldItem[];
BEGIN
    -- All Building Pieces
    SELECT array_agg((instance_id, building_type, transform, provides_stability, health, hologram)::BuildingBlueprintItem)
		into buildings_array
		FROM building_blueprint_instances
		WHERE building_blueprint_id = in_building_blueprint_id;

    -- All Placeables
    SELECT array_agg((placeable_id, building_type, transform, hologram)::BuildingBlueprintPlaceableItem)
		into placeables_array
		FROM building_blueprint_placeables
		WHERE building_blueprint_id = in_building_blueprint_id;

    -- Pentashields
    SELECT array_agg((placeable_id, scale)::BuildingBlueprintPentashieldItem)
		into pentashields_array
		FROM building_blueprint_pentashields
		WHERE building_blueprint_id = in_building_blueprint_id;

    return ROW(buildings_array, placeables_array, pentashields_array)::BuildingBlueprintGetCopyData;
END
$function$
