-- update_item_locations(in_item_locations dune.inventoryitemlocation[]) -> void
-- oid: 58624  kind: FUNCTION  category: inventory

CREATE OR REPLACE FUNCTION dune.update_item_locations(in_item_locations dune.inventoryitemlocation[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE items
    SET inventory_id = (item).inventory_id, position_index = (item).position_index
        FROM (SELECT item_id, inventory_id, position_index FROM UNNEST(in_item_locations)) item
    WHERE id = (item).item_id;

	-- log item tracking
    PERFORM _add_item_trace_log('update_item_locations', in_item_locations);
END
$function$
