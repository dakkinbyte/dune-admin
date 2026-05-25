-- delete_items(in_ids bigint[]) -> void
-- oid: 58215  kind: FUNCTION  category: inventory

CREATE OR REPLACE FUNCTION dune.delete_items(in_ids bigint[])
 RETURNS void
 LANGUAGE sql
AS $function$
	DELETE FROM items i
	USING inventories inv
	WHERE i.inventory_id = inv.id
	AND i.id = ANY (in_ids)
	RETURNING _add_item_delete_log(
		i.id,
		inv.id,
		i.template_id
	);
$function$
