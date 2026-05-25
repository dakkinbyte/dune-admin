-- dune_exchange_get_item_price_stats(in_template_ids text[]) -> TABLE(template_id text, minimum bigint, average bigint)
-- oid: 58246  kind: FUNCTION  category: inventory

CREATE OR REPLACE FUNCTION dune.dune_exchange_get_item_price_stats(in_template_ids text[])
 RETURNS TABLE(template_id text, minimum bigint, average bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE
	average_price REAL;
	minimum_price REAL;
BEGIN
	RETURN QUERY SELECT ord.template_id, MIN(sord.wear_normalized_price), CAST(SUM(sord.wear_normalized_price * item.stack_size) / SUM(item.stack_size) AS BIGINT)
	FROM dune_exchange_orders ord
	JOIN items item ON item.id = ord.item_id
	JOIN dune_exchange_sell_orders sord ON sord.order_id = ord.id
	WHERE ord.template_id = ANY(in_template_ids) GROUP BY ord.template_id;
END $function$
