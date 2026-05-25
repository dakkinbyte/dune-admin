-- initialize_partitions_editor_default_1x1() -> void
-- oid: 58383  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.initialize_partitions_editor_default_1x1()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	perform add_partition_unique('Editor_Default', '{"type": "box2d_array", "boxes": [{"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}]}', 0, 'Editor_Default');
END;
$function$
