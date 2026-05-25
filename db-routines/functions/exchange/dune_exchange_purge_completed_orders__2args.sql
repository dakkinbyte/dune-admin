-- dune_exchange_purge_completed_orders(in_exchange_id bigint, in_current_time bigint) -> SETOF dune.exchangeexpiredorder
-- oid: 58249  kind: FUNCTION  category: exchange

CREATE OR REPLACE FUNCTION dune.dune_exchange_purge_completed_orders(in_exchange_id bigint, in_current_time bigint)
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
			sord.stack_size AS stack_size,
			ord.item_price AS item_price,
			sord.completion_type AS completion_type,
			sord.original_order_id AS original_order_id,
            ord.quality_level AS quality_level
		FROM dune_exchange_orders ord
		JOIN dune_exchange_fulfilled_orders sord ON (ord.id = sord.order_id)
		WHERE ord.exchange_id = in_exchange_id AND ord.expiration_time IS NOT NULL AND in_current_time >= ord.expiration_time
		FOR UPDATE
	LOOP
		DELETE FROM dune_exchange_orders WHERE id = cur_order.order_id;
		RETURN NEXT (
			cur_order.order_id,
			cur_order.owner_id,
			cur_order.completion_type,
			cur_order.stack_size,
			cur_order.item_price,
			cur_order.original_order_id,
            cur_order.quality_level);
	END LOOP;
END $function$
