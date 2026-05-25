-- initialize_partitions_igw_test_small_2x2() -> void
-- oid: 58386  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.initialize_partitions_igw_test_small_2x2()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	perform add_partition_unique('IGW_Test_Small', '{"type": "box2d_array", "boxes": [{"max_x": 0.5, "max_y": 0.5, "min_x": 0, "min_y": 0}]}', 0, 'IGW_Test_Small_A1');
	perform add_partition_unique('IGW_Test_Small', '{"type": "box2d_array", "boxes": [{"max_x": 0.5, "max_y": 1, "min_x": 0, "min_y": 0.5}]}', 0, 'IGW_Test_Small_A2');
	perform add_partition_unique('IGW_Test_Small', '{"type": "box2d_array", "boxes": [{"max_x": 1, "max_y": 0.5, "min_x": 0.5, "min_y": 0}]}', 0, 'IGW_Test_Small_B1');
	perform add_partition_unique('IGW_Test_Small', '{"type": "box2d_array", "boxes": [{"max_x": 1, "max_y": 1, "min_x": 0.5, "min_y": 0.5}]}', 0, 'IGW_Test_Small_B2');
END;
$function$
