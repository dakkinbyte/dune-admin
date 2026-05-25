-- dune_exchange_retrieve_storage_item(in_exchange_id bigint, in_order_id bigint, in_dst_inventory_id bigint, in_dst_index bigint, in_count bigint) -> dune.duneexchangeretrievestorageorderresult
-- oid: 58255  kind: FUNCTION  category: exchange

CREATE OR REPLACE FUNCTION dune.dune_exchange_retrieve_storage_item(in_exchange_id bigint, in_order_id bigint, in_dst_inventory_id bigint, in_dst_index bigint, in_count bigint)
 RETURNS dune.duneexchangeretrievestorageorderresult
 LANGUAGE plpgsql
AS $function$
DECLARE
	exchange_inventory_id BIGINT;
	order_owner_id BIGINT;
	order_item_id BIGINT;
	result DuneExchangeRetrieveStorageOrderResult;
BEGIN
	SELECT INTO exchange_inventory_id get_exchange_inventory_id(in_exchange_id);

	IF exchange_inventory_id IS NULL THEN
		RETURN NULL;
	END IF;

	SELECT INTO STRICT order_owner_id, order_item_id owner_id, item_id
	FROM dune_exchange_orders
	JOIN dune_exchange_fulfilled_orders ON (dune_exchange_orders.id = dune_exchange_fulfilled_orders.order_id)
	WHERE id = in_order_id
	FOR UPDATE;

	UPDATE dune_exchange_orders SET item_id = NULL WHERE id = in_order_id;

	SELECT INTO result.item_id move_inventory_item(order_item_id, in_dst_inventory_id, in_dst_index, in_count);

	IF result.item_id IS NULL THEN
		RAISE EXCEPTION 'Failed to move inventory item % on order %', in_item_id, in_order_id;
	END IF;

    SELECT INTO result.original_order_id original_order_id FROM dune_exchange_fulfilled_orders WHERE order_id = in_order_id;

	-- If the new ID is equal to the old ID the item/stack was moved rather than split and the order is now empty
	IF result.item_id = order_item_id THEN
		DELETE FROM dune_exchange_orders WHERE id = in_order_id;
	ELSE
		UPDATE dune_exchange_orders SET item_id = order_item_id WHERE id = in_order_id; -- Item was split. Restore reference to remaining items.
		UPDATE dune_exchange_fulfilled_orders SET stack_size = stack_size - in_count WHERE order_id = in_order_id;
	END IF;

	SELECT INTO result.order_slots_used get_dune_exchange_used_order_slots(order_owner_id);

	RETURN result;
END $function$
