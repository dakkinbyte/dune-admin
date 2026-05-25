-- move_inventory_item(in_item_id bigint, in_dst_inventory_id bigint, in_dst_index bigint, in_count bigint) -> bigint
-- oid: 58478  kind: FUNCTION  category: inventory

CREATE OR REPLACE FUNCTION dune.move_inventory_item(in_item_id bigint, in_dst_inventory_id bigint, in_dst_index bigint, in_count bigint)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	remaining_stack_size BIGINT;
	new_item_id BIGINT;
	item_data items%ROWTYPE;
BEGIN
	SELECT INTO STRICT item_data * FROM items WHERE id = in_item_id;

	remaining_stack_size := item_data.stack_size - in_count;

	IF remaining_stack_size < 0 THEN
		RETURN NULL;
	END IF;

    -- log item tracking
    PERFORM _add_item_trace_log('move_inventory_item', in_item_id, in_dst_inventory_id, NULL, in_dst_index);
        
	IF remaining_stack_size > 0 THEN
		item_data.stack_size := in_count;
		item_data.position_index := in_dst_index;
		item_data.inventory_id := in_dst_inventory_id;
		SELECT INTO item_data.id nextval('items_id_seq');
		INSERT INTO items VALUES(item_data.*) RETURNING id INTO new_item_id;
		UPDATE items SET stack_size = remaining_stack_size WHERE id = in_item_id;
	ELSE
		UPDATE items SET inventory_id = in_dst_inventory_id, position_index = in_dst_index WHERE id = in_item_id;
		new_item_id := in_item_id;
	END IF;

	RETURN new_item_id;
END $function$
