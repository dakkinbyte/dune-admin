-- get_exchange_orders_by_mask(in_mask integer, in_depth smallint) -> SETOF bigint
-- oid: 58301  kind: FUNCTION  category: exchange

CREATE OR REPLACE FUNCTION dune.get_exchange_orders_by_mask(in_mask integer, in_depth smallint)
 RETURNS SETOF bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	check_mask INT;
	check_shift INT;
BEGIN
	check_shift := (4 - in_depth) * 8;
	check_mask := (in_mask >> check_shift);
	RETURN query SELECT id FROM dune_exchange_orders WHERE category_depth >= in_depth AND (category_mask >> check_shift) = check_mask FOR SHARE;
END
$function$
