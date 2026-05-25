-- delete_inventory_item(in_item_id bigint, in_count bigint) -> bigint
-- oid: 58213  kind: FUNCTION  category: inventory

CREATE OR REPLACE FUNCTION dune.delete_inventory_item(in_item_id bigint, in_count bigint)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	remaining_stack_size BIGINT;
BEGIN
	SELECT INTO STRICT remaining_stack_size stack_size FROM items WHERE id = in_item_id;

	remaining_stack_size := remaining_stack_size - in_count;

	IF remaining_stack_size < 0 THEN
		RETURN NULL;
	END IF;

	IF remaining_stack_size > 0 THEN
		UPDATE items SET stack_size = remaining_stack_size WHERE id = in_item_id;
	ELSE
		PERFORM delete_item(in_item_id);
	END IF;
	RETURN remaining_stack_size;
END $function$
