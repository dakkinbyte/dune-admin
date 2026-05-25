-- dune_exchange_cancel_order(in_order_id bigint, in_purge_time bigint, in_completion_type integer) -> void
-- oid: 58242  kind: FUNCTION  category: exchange

CREATE OR REPLACE FUNCTION dune.dune_exchange_cancel_order(in_order_id bigint, in_purge_time bigint, in_completion_type integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
BEGIN
	DELETE FROM dune_exchange_sell_orders WHERE order_id = in_order_id;
	IF NOT FOUND THEN
		RETURN;
	END IF;

	WITH item_stack_size AS
		(SELECT item.stack_size
			FROM dune_exchange_orders ord
			JOIN items item ON ord.item_id = item.id
			WHERE ord.id = in_order_id)
		INSERT INTO dune_exchange_fulfilled_orders(order_id, completion_type, stack_size, original_order_id) VALUES(in_order_id, in_completion_type, (SELECT * FROM item_stack_size), in_order_id);

	UPDATE dune_exchange_orders SET expiration_time = in_purge_time, revision = revision + 1 WHERE id = in_order_id;
END $function$
