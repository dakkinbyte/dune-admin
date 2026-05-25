-- update_inventory(in_delete_list bigint[], in_stack_update dune.itemstackupdate[], in_quality_update dune.itemqualityupdate[], in_stat_update dune.itemstatupdate[], in_item_locations dune.inventoryitemlocation[]) -> void
-- oid: 58623  kind: FUNCTION  category: inventory

CREATE OR REPLACE FUNCTION dune.update_inventory(in_delete_list bigint[], in_stack_update dune.itemstackupdate[], in_quality_update dune.itemqualityupdate[], in_stat_update dune.itemstatupdate[], in_item_locations dune.inventoryitemlocation[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    delete_item_id BIGINT;
BEGIN
    -- log item movement
    PERFORM _add_item_trace_log('update_inventory_locations', in_item_locations);
    
	-- delete items
	PERFORM delete_items(in_delete_list);

	-- update item stacks
	UPDATE items SET "stack_size" = (u).stack_size FROM (SELECT stack_size, item_id FROM UNNEST(in_stack_update)) u WHERE "id" = (u).item_id;

	-- update item quality
	UPDATE items SET "quality_level" = (u).quality_level FROM (SELECT quality_level, item_id FROM UNNEST(in_quality_update)) u WHERE "id" = (u).item_id;

	-- update stats
	UPDATE items SET "stats" = "stats" || (u).value FROM (SELECT value, item_id FROM UNNEST(in_stat_update)) u WHERE "id" = (u).item_id;

    UPDATE items
    SET inventory_id = (item).inventory_id, position_index = (item).position_index
        FROM (SELECT item_id, inventory_id, position_index FROM UNNEST(in_item_locations)) item
    WHERE id = (item).item_id;
END
$function$
