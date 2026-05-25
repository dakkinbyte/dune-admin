-- determine_partition_label_trigger() -> trigger
-- oid: 58236  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.determine_partition_label_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
	IF NEW.label IS NULL THEN
		UPDATE world_partition
		SET label = determine_partition_label(NEW.map, NEW.dimension_index, NULL, false)
		WHERE partition_id = NEW.partition_id;
	END IF;

	RETURN NULL; -- AFTER ROW trigger does not need to return a row
END;
$function$
