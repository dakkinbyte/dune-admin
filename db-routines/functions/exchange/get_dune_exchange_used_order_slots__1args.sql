-- get_dune_exchange_used_order_slots(in_controller_id bigint) -> integer
-- oid: 58299  kind: FUNCTION  category: exchange

CREATE OR REPLACE FUNCTION dune.get_dune_exchange_used_order_slots(in_controller_id bigint)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
	result INT;
BEGIN
	SELECT INTO result COUNT(*) FROM dune_exchange_orders where owner_id=in_controller_id AND item_id IS NOT NULL;

	RETURN result;
END $function$
