-- delete_items_from_actor(in_actor_id bigint) -> void
-- oid: 58216  kind: FUNCTION  category: inventory

CREATE OR REPLACE FUNCTION dune.delete_items_from_actor(in_actor_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	PERFORM delete_items(
		(
	        SELECT array_agg(i.id)
	        FROM items i
	        JOIN inventories inv ON inv.id = i.inventory_id
	        WHERE inv.actor_id = in_actor_id
		)
	);
END $function$
