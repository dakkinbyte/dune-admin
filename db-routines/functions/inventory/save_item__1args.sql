-- save_item(in_item dune.inventoryitem) -> void
-- oid: 58547  kind: FUNCTION  category: inventory

CREATE OR REPLACE FUNCTION dune.save_item(in_item dune.inventoryitem)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
	INSERT INTO
		items (id, inventory_id, stack_size, quality_level, volume_override, position_index, template_id, stats, is_new, acquisition_time)
		VALUES (
			(in_item).item_id,
			(in_item).inventory_id,
			(in_item).stack_size,
			(in_item).quality_level,
            (in_item).volume_override,
			(in_item).position_index,
			(in_item).template_id,
			(in_item).stats,
			(in_item).is_new,
			(in_item).acquisition_time
		)
		ON CONFLICT (id)
			DO UPDATE SET
				inventory_id = (in_item).inventory_id,
				stack_size = (in_item).stack_size,
                quality_level = (in_item).quality_level,
                volume_override = (in_item).volume_override,
				position_index = (in_item).position_index,
				template_id = (in_item).template_id,
				stats = items.stats || (in_item).stats,
				is_new = (in_item).is_new,
				acquisition_time = (in_item).acquisition_time;
    
    -- log item tracking
    PERFORM _add_item_trace_log('save_item', (in_item).item_id, (in_item).inventory_id, (in_item).template_id, (in_item).position_index);
end
$function$
