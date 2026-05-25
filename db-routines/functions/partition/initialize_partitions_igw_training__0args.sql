-- initialize_partitions_igw_training() -> void
-- oid: 58387  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.initialize_partitions_igw_training()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	perform add_partition_unique('IGW_Training', '{"type": "box2d_array", "boxes": [{"max_x": 1, "max_y": 0.33333, "min_x": 0, "min_y": 0}]}', 0, 'IGW_Training_A1');
	perform add_partition_unique('IGW_Training', '{"type": "box2d_array", "boxes": [{"max_x": 1, "max_y": 0.66667, "min_x": 0, "min_y": 0.33333}]}', 0, 'IGW_Training_A2');
	perform add_partition_unique('IGW_Training', '{"type": "box2d_array", "boxes": [{"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0.66667}]}', 0, 'IGW_Training_A3');
END;
$function$
