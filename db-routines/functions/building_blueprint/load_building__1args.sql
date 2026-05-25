-- load_building(in_building_id bigint) -> dune.buildingsavedata
-- oid: 58449  kind: FUNCTION  category: building_blueprint

CREATE OR REPLACE FUNCTION dune.load_building(in_building_id bigint)
 RETURNS dune.buildingsavedata
 LANGUAGE sql
BEGIN ATOMIC
 RETURN ( SELECT ROW(array_agg(ROW(building_instances.instance_id, building_instances.building_type, building_instances.transform, building_instances.owner_entity_id, building_instances.building_flags, building_instances.health, building_instances.shelter, building_instances.stabilization_begin_timespan, building_instances.stabilization_end_timespan, building_instances.stabilization_state, building_instances.sand_buildup)::dune.buildinginstance), ARRAY[]::integer[], ARRAY[]::dune.buildinginstanceupdateowner[], ARRAY[]::dune.buildinginstanceupdatestabilization[], ARRAY[]::dune.buildinginstanceupdatehealth[], ARRAY[]::dune.buildinginstanceupdateshelter[], ARRAY[]::dune.buildinginstanceupdatesandbuildup[], ARRAY[]::dune.buildinginstanceupdatebuildingflags[], ARRAY[]::dune.buildinginstanceupdatetransform[])::dune.buildingsavedata AS "row"
            FROM dune.building_instances
           WHERE (building_instances.building_id = load_building.in_building_id));
END
