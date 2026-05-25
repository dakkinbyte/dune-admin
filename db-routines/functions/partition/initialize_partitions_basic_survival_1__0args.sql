-- initialize_partitions_basic_survival_1() -> void
-- oid: 58381  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.initialize_partitions_basic_survival_1()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	perform add_partition_unique('Survival_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('Survival_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 1);
	perform add_partition_unique('Survival_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 2);
	perform add_partition_unique('Survival_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 3);
	perform update_partition_labels();
END;
$function$
