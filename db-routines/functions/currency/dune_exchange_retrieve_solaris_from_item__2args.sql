-- dune_exchange_retrieve_solaris_from_item(in_controller_id bigint, in_order_id bigint) -> dune.duneexchangeretrievesolarisfromitemresult
-- oid: 58254  kind: FUNCTION  category: currency

CREATE OR REPLACE FUNCTION dune.dune_exchange_retrieve_solaris_from_item(in_controller_id bigint, in_order_id bigint)
 RETURNS dune.duneexchangeretrievesolarisfromitemresult
 LANGUAGE plpgsql
AS $function$
DECLARE
	result DuneExchangeRetrieveSolarisFromItemResult;
	new_balance BIGINT;
	function_oid oid;
BEGIN
	WITH
		delete_orders_prices AS (
			DELETE FROM dune_exchange_orders
				USING dune_exchange_fulfilled_orders
				WHERE (dune_exchange_orders.id = dune_exchange_fulfilled_orders.order_id)
					AND id = in_order_id AND (item_id IS NULL OR item_id = 0)
			RETURNING item_price * dune_exchange_fulfilled_orders.stack_size AS total_price
		),
		total_price AS (
			SELECT SUM(total_price) AS delta FROM delete_orders_prices
		)
	UPDATE player_virtual_currency_balances 
		SET balance = balance + total_price.delta
		FROM total_price
		WHERE currency_id = get_solaris_id() AND player_controller_id = in_controller_id
		RETURNING
			player_virtual_currency_balances.balance,
            total_price.delta, 
            (SELECT original_order_id FROM dune_exchange_fulfilled_orders WHERE order_id = in_order_id) 
        INTO
			new_balance,
            result.total_item_value,
            result.original_order_id;
	
	GET DIAGNOSTICS function_oid = PG_ROUTINE_OID;
	PERFORM log_event_solaris(function_oid, 'update_solaris', in_controller_id, new_balance, result.total_item_value);

	RETURN result;
END $function$
