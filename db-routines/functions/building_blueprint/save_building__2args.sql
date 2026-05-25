-- save_building(in_building_id bigint, in_data dune.buildingsavedata) -> void
-- oid: 58543  kind: FUNCTION  category: building_blueprint

CREATE OR REPLACE FUNCTION dune.save_building(in_building_id bigint, in_data dune.buildingsavedata)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	instance BUILDINGINSTANCE;
	instance_to_remove INTEGER;
	instance_owner BuildingInstanceUpdateOwner;
BEGIN
	-- ADD
	IF array_length(in_data.in_add_building_data, 1) > 0 THEN
		INSERT INTO building_instances(
			"building_id",
			"instance_id",
			"building_type",
			"transform",
			"owner_entity_id",
			"building_flags",
			"health",
			"shelter",
			"stabilization_begin_timespan",
			"stabilization_end_timespan",
			"stabilization_state",
			"sand_buildup"
		)
		SELECT
			in_building_id,
			add_data.instance_id,
			add_data.building_type,
			add_data.transform,
			_building_validate_totem_owner_id(add_data.owner_entity_id),
			add_data.building_flags,
			add_data.health,
			add_data.shelter,
			add_data.stabilization_begin_timespan,
			add_data.stabilization_end_timespan,
			add_data.stabilization_state,
			add_data.sand_buildup
		FROM unnest(in_data.in_add_building_data) as add_data
		ON CONFLICT ("building_id", "instance_id")
			DO UPDATE SET
				"building_type" = (instance).building_type,
				"transform" = (instance).transform,
				"owner_entity_id" = _building_validate_totem_owner_id((instance).owner_entity_id),
				"building_flags" = (instance).building_flags,
				"health" = (instance).health,
				"shelter" = (instance).shelter,
				"stabilization_begin_timespan" = (instance).stabilization_begin_timespan,
				"stabilization_end_timespan" = (instance).stabilization_end_timespan,
				"stabilization_state" = (instance).stabilization_state,
				"sand_buildup" = (instance).sand_buildup;
	END IF;

	-- REMOVE
	IF array_length(in_data.in_remove_building_data, 1) > 0 THEN
		DELETE FROM building_instances
			WHERE building_instances."building_id" = in_building_id AND building_instances."instance_id" = ANY(in_data.in_remove_building_data);
	END IF;

	-- OWNER. 99.99% of the time, this will only have 1 Owner Array.
	IF array_length(in_data.in_building_owner_data, 1) > 0 THEN
		FOREACH instance_owner IN ARRAY in_data.in_building_owner_data LOOP
			WITH owner_changes_table AS
			(
				SELECT unnest(instance_owner.instances) AS instance_id, instance_owner.owner_entity_id AS owner_entity_id
			)
			UPDATE building_instances
				SET owner_entity_id = _building_validate_totem_owner_id(owner_changes_table.owner_entity_id)
			FROM owner_changes_table
			WHERE building_instances.building_id = in_building_id AND building_instances.instance_id = owner_changes_table.instance_id;
		END LOOP;
	END IF;

	-- STABILIZATION
	IF array_length(in_data.in_building_stabilization_data, 1) > 0 THEN
		WITH stabilization_changes_table AS
		(
			select * FROM unnest(in_data.in_building_stabilization_data)
		)
		UPDATE building_instances SET stabilization_begin_timespan = stabilization_changes_table.stabilization_begin_timespan, stabilization_end_timespan = stabilization_changes_table.stabilization_end_timespan, stabilization_state = stabilization_changes_table.stabilization_state
		FROM stabilization_changes_table
		WHERE building_instances.building_id = in_building_id AND building_instances.instance_id = stabilization_changes_table.instance_id;
	END IF;

	-- HEALTH
	IF array_length(in_data.in_building_health_data, 1) > 0 THEN
		WITH health_changes_table AS
		(
			select * FROM unnest(in_data.in_building_health_data)
		)
		UPDATE building_instances SET health = health_changes_table.health
		FROM health_changes_table
		WHERE building_instances.building_id = in_building_id AND building_instances.instance_id = health_changes_table.instance_id;
	END IF;

	-- SHELTER
	IF array_length(in_data.in_building_shelter_data, 1) > 0 THEN
		WITH shelter_changes_table AS
		(
			select * FROM unnest(in_data.in_building_shelter_data)
		)
		UPDATE building_instances SET shelter = shelter_changes_table.shelter
		FROM shelter_changes_table
		WHERE building_instances.building_id = in_building_id AND building_instances.instance_id = shelter_changes_table.instance_id;
	END IF;

	-- SAND BUILDUP
	IF array_length(in_data.in_building_sand_buildup_data, 1) > 0 THEN
		WITH sand_buildup_changes_table AS
		(
			select * FROM unnest(in_data.in_building_sand_buildup_data)
		)
		UPDATE building_instances SET sand_buildup = sand_buildup_changes_table.sand_buildup
		FROM sand_buildup_changes_table
		WHERE building_instances.building_id = in_building_id AND building_instances.instance_id = sand_buildup_changes_table.instance_id;
	END IF;

	-- BUILDING FLAGS
	IF array_length(in_data.in_building_building_flags_data, 1) > 0 THEN
		WITH building_flags_changes_table AS
		(
			select * FROM unnest(in_data.in_building_building_flags_data)
		)
		UPDATE building_instances SET building_flags = building_flags_changes_table.building_flags
		FROM building_flags_changes_table
		WHERE building_instances.building_id = in_building_id AND building_instances.instance_id = building_flags_changes_table.instance_id;
	END IF;

	-- BUILDING TRANSFORM
	IF array_length(in_data.in_building_building_transform_data, 1) > 0 THEN
		WITH building_flags_transform_table AS
		(
			select * FROM unnest(in_data.in_building_building_transform_data)
		)
		UPDATE building_instances SET transform = building_flags_transform_table.transform
		FROM building_flags_transform_table
		WHERE building_instances.building_id = in_building_id AND building_instances.instance_id = building_flags_transform_table.instance_id;
	END IF;
END
$function$
