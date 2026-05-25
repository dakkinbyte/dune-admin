-- update_sell_orders_categories(category_update_data dune.exchangecategoryupdatedata[]) -> void
-- oid: 58634  kind: FUNCTION  category: misc

CREATE OR REPLACE FUNCTION dune.update_sell_orders_categories(category_update_data dune.exchangecategoryupdatedata[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
BEGIN
	UPDATE dune_exchange_orders SET category_mask = update_data.mask, category_depth = update_data.depth
	FROM UNNEST(category_update_data) update_data
	WHERE update_data.item_template_id = dune_exchange_orders.template_id;
END
$function$
