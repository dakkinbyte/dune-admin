-- delete_item(in_id bigint) -> void
-- oid: 58214  kind: FUNCTION  category: inventory

CREATE OR REPLACE FUNCTION dune.delete_item(in_id bigint)
 RETURNS void
 LANGUAGE sql
AS $function$
	DELETE FROM items i
	USING inventories inv
	WHERE i.inventory_id = inv.id
	AND i.id = in_id
	RETURNING _add_item_delete_log(
		i.id,
		inv.id,
		i.template_id
	);
$function$
