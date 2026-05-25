-- merge_or_move_inventory_item(in_item_id bigint, in_dst_inventory_id bigint, in_dst_index bigint, in_count bigint) -> bigint
-- oid: 58475  kind: FUNCTION  category: inventory

CREATE OR REPLACE FUNCTION dune.merge_or_move_inventory_item(in_item_id bigint, in_dst_inventory_id bigint, in_dst_index bigint, in_count bigint)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	remaining_stack_size BIGINT;
	new_item_id BIGINT;
	item_data items%ROWTYPE;
	dst_item_data items%ROWTYPE;
BEGIN
	SELECT INTO new_item_id merge_inventory_items(in_item_id, in_dst_inventory_id, in_dst_index, in_count);

	IF new_item_id IS NULL THEN
		SELECT INTO new_item_id move_inventory_item(in_item_id, in_dst_inventory_id, in_dst_index, in_count);
	END IF;

	RETURN new_item_id;
END $function$
