-- dune_exchange_relist_order(in_order_id bigint, in_expiration_time bigint, in_item_price bigint, in_wear_normalized_item_price bigint, in_solari_cost bigint) -> bigint
-- oid: 58252  kind: FUNCTION  category: exchange

CREATE OR REPLACE FUNCTION dune.dune_exchange_relist_order(in_order_id bigint, in_expiration_time bigint, in_item_price bigint, in_wear_normalized_item_price bigint, in_solari_cost bigint)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	user_id BIGINT;
	initial_stack_size BIGINT;
BEGIN
	WITH order_owner_id AS
		(SELECT ord.owner_id
			FROM dune_exchange_orders ord
			JOIN dune_exchange_fulfilled_orders ford ON (ord.id = ford.order_id)
			WHERE id = in_order_id AND item_id IS NOT NULL)
		SELECT INTO user_id dune_exchange_get_user_id((SELECT * FROM order_owner_id));

	UPDATE dune_exchange_users SET solari_balance = solari_balance - in_solari_cost WHERE id = user_id AND solari_balance >= in_solari_cost;

	IF NOT FOUND THEN
		RETURN 0;
	END IF;

	DELETE FROM dune_exchange_fulfilled_orders WHERE order_id = in_order_id;

	IF NOT FOUND THEN
		RAISE EXCEPTION 'Order % is not a fulfilled order', in_order_id;
	END IF;

	WITH item_stack_size AS
		(SELECT item.stack_size
			FROM dune_exchange_orders ord
			JOIN items item ON ord.item_id = item.id
			WHERE ord.id = in_order_id)
		INSERT INTO dune_exchange_sell_orders(order_id, initial_stack_size, wear_normalized_price) VALUES(in_order_id, (SELECT * FROM item_stack_size), in_wear_normalized_item_price) RETURNING dune_exchange_sell_orders.initial_stack_size INTO initial_stack_size;

	UPDATE dune_exchange_orders SET item_price = in_item_price, expiration_time = in_expiration_time WHERE id = in_order_id;

	RETURN initial_stack_size;
END $function$
