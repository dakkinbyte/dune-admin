-- update_partition_labels(in_allow_overwrite boolean) -> void
-- oid: 58627  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.update_partition_labels(in_allow_overwrite boolean DEFAULT true)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	-- Compute candidate labels per-partition using the helper and apply them where appropriate
	UPDATE world_partition wp
	SET label = sub.new_label
	FROM (
		SELECT partition_id, determine_partition_label(map, dimension_index, label, in_allow_overwrite, partition_id) AS new_label
		FROM world_partition
	) AS sub
	WHERE wp.partition_id = sub.partition_id
	  AND (wp.label IS NULL OR in_allow_overwrite = true)
	  AND sub.new_label IS NOT NULL;

	-- The default is `MAP_DIMENSION`
	-- Only set it for map, dimension combos that have a single partition (label must be unique), and for labels not already touched
	UPDATE world_partition SET label = map || '_' || dimension_index
	from (
		select grouping.partition_ids[1] as partition_id
			from (
				select count(*) as count, array_agg(partition_id) as partition_ids
				from world_partition
				group by map, dimension_index
			) as grouping
			where grouping.count = 1
	) as partition
	where
		world_partition.partition_id = partition.partition_id
		and label is null;
END;
$function$
