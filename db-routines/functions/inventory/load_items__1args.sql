-- load_items(in_inventory_id bigint) -> TABLE(item_id bigint, stack_size bigint, quality_level bigint, volume_override real, position_index bigint, template_id text, inventory_id bigint, is_new boolean, acquisition_time bigint, stats jsonb, sub_inventory_id bigint)
-- oid: 58456  kind: FUNCTION  category: inventory

CREATE OR REPLACE FUNCTION dune.load_items(in_inventory_id bigint)
 RETURNS TABLE(item_id bigint, stack_size bigint, quality_level bigint, volume_override real, position_index bigint, template_id text, inventory_id bigint, is_new boolean, acquisition_time bigint, stats jsonb, sub_inventory_id bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
RETURN QUERY
WITH RECURSIVE items_cte AS (
    SELECT item.id, item.stack_size, item.quality_level, item.volume_override, item.position_index, item.template_id, item.inventory_id, item.is_new, item.acquisition_time, item.stats, inventory.id as sub_inventory_id
    FROM items item
    LEFT JOIN inventories inventory ON (inventory.item_id = item.id)
    WHERE item.inventory_id = in_inventory_id
    UNION ALL
    SELECT item.id, item.stack_size, item.quality_level, item.volume_override, item.position_index, item.template_id, item.inventory_id, item.is_new, item.acquisition_time, item.stats, inventory.id as sub_inventory_id
    FROM items item
    LEFT JOIN inventories inventory ON (inventory.item_id = item.id)
    JOIN items_cte ON item.inventory_id = items_cte.sub_inventory_id
    WHERE items_cte.sub_inventory_id IS NOT NULL
)
SELECT * FROM items_cte order by id asc;
END; $function$
