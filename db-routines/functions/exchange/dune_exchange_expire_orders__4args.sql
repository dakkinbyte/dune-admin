-- dune_exchange_expire_orders(in_exchange_id bigint, in_current_time bigint, in_purge_time bigint, in_expired_completion_type integer) -> SETOF dune.exchangeexpiredorder
-- oid: 58243  kind: FUNCTION  category: exchange

CREATE OR REPLACE FUNCTION dune.dune_exchange_expire_orders(in_exchange_id bigint, in_current_time bigint, in_purge_time bigint, in_expired_completion_type integer)
 RETURNS SETOF dune.exchangeexpiredorder
 LANGUAGE plpgsql
AS $function$
DECLARE
	cur_order RECORD;
	order_is_npc_order BOOLEAN;
BEGIN
	FOR cur_order IN
		SELECT 
			ord.id AS order_id,
			ord.owner_id AS owner_id,
			ord.is_npc_order AS is_npc_order,
			item.stack_size AS stack_size,
			ord.item_price AS item_price,
            ord.quality_level AS quality_level
		FROM dune_exchange_orders ord
		JOIN dune_exchange_sell_orders sord ON (ord.id = sord.order_id)
		JOIN items item ON (ord.item_id = item.id)
		WHERE ord.exchange_id = in_exchange_id AND ord.expiration_time IS NOT NULL AND in_current_time >= ord.expiration_time
		FOR UPDATE
	LOOP
		IF NOT cur_order.is_npc_order THEN
			-- Make an item_storage record for the order item.
			DELETE FROM dune_exchange_sell_orders WHERE order_id = cur_order.order_id;
			INSERT INTO dune_exchange_fulfilled_orders(order_id, completion_type, stack_size, original_order_id) VALUES(cur_order.order_id, in_expired_completion_type, cur_order.stack_size, cur_order.order_id);
			UPDATE dune_exchange_orders SET revision = revision + 1, expiration_time = in_purge_time WHERE id = cur_order.order_id;

			RETURN NEXT (
				cur_order.order_id,
				cur_order.owner_id,
				in_expired_completion_type,
				cur_order.stack_size,
				cur_order.item_price,
				cur_order.order_id,
                cur_order.quality_level);
		ELSE
			-- Delete the order. Will cascade into the items table.
			DELETE FROM dune_exchange_orders WHERE id = order_id;
		END IF;

	END LOOP;
END $function$
