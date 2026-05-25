-- merge_inventory_items(in_item_id bigint, in_dst_inventory_id bigint, in_dst_index bigint, in_count bigint) -> bigint
-- oid: 58474  kind: FUNCTION  category: inventory

CREATE OR REPLACE FUNCTION dune.merge_inventory_items(in_item_id bigint, in_dst_inventory_id bigint, in_dst_index bigint, in_count bigint)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	remaining_stack_size BIGINT;
	item_data items%ROWTYPE;
	dst_item_data items%ROWTYPE;
BEGIN
	SELECT INTO STRICT item_data * FROM items WHERE id = in_item_id;

	SELECT INTO dst_item_data * FROM items WHERE inventory_id = in_dst_inventory_id AND position_index = in_dst_index;

	IF dst_item_data.id IS NULL THEN
		RETURN NULL;
	END IF;

	remaining_stack_size := item_data.stack_size - in_count;

	IF remaining_stack_size < 0 THEN
		RETURN NULL;
	END IF;


	IF item_data.template_id != dst_item_data.template_id THEN
		RETURN NULL;
	END IF;
    
    -- log item tracking
    PERFORM _add_item_trace_log('merge_inventory_items', in_item_id, in_dst_inventory_id, NULL, in_dst_index);
    
	IF remaining_stack_size > 0 THEN
		UPDATE items SET stack_size = remaining_stack_size WHERE id = in_item_id;
	ELSE
		PERFORM delete_item(in_item_id);
	END IF;
	UPDATE items SET stack_size = dst_item_data.stack_size + in_count WHERE id = dst_item_data.id;

	RETURN dst_item_data.id;
END $function$
