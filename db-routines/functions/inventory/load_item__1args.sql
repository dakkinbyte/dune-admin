-- load_item(in_item_id bigint) -> TABLE(item_id bigint, stack_size bigint, quality_level bigint, volume_override real, position_index bigint, template_id text, inventory_id bigint, is_new boolean, acquisition_time bigint, stats jsonb, sub_inventory_id bigint)
-- oid: 58455  kind: FUNCTION  category: inventory

CREATE OR REPLACE FUNCTION dune.load_item(in_item_id bigint)
 RETURNS TABLE(item_id bigint, stack_size bigint, quality_level bigint, volume_override real, position_index bigint, template_id text, inventory_id bigint, is_new boolean, acquisition_time bigint, stats jsonb, sub_inventory_id bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT item.id, item.stack_size, item.quality_level, item.volume_override, item.position_index, item.template_id, item.inventory_id, item.is_new, item.acquisition_time, item.stats, inventory.id
    FROM items item
    LEFT JOIN inventories inventory ON (inventory.item_id = item.id)
    WHERE item.id = in_item_id;
END; $function$
