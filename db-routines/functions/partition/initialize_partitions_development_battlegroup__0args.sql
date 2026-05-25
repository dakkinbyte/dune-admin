-- initialize_partitions_development_battlegroup() -> void
-- oid: 58382  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.initialize_partitions_development_battlegroup()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	-- Current battlegroup maps
	perform initialize_partitions_full_battlegroup();

	-- Core development maps
	perform initialize_partitions_editor_default_1x1();
	perform initialize_partitions_igw_test_small_2x2();
	perform initialize_partitions_igw_training();

	-- Additional Gyms
	perform add_partition_unique('CombatGym_01', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0, 'CombatGym_01');
	perform add_partition_unique('Audio_Gym', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0, 'Audio_Gym');
	perform add_partition_unique('CombatGym_Camps', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0, 'CombatGym_Camps');
END;
$function$
