-- get_exchange_sell_orders_by_item_type(in_exchange_id bigint, in_template_ids text[]) -> TABLE(id bigint, revision bigint, expiration_time bigint, access_point_id bigint, ap_name text, owner_id bigint, template_id text, stack_size bigint, initial_stack_size bigint, item_price bigint, quality_level bigint, durability_cur real, durability_max real, dynamic_stats jsonb)
-- oid: 58303  kind: FUNCTION  category: inventory

CREATE OR REPLACE FUNCTION dune.get_exchange_sell_orders_by_item_type(in_exchange_id bigint, in_template_ids text[])
 RETURNS TABLE(id bigint, revision bigint, expiration_time bigint, access_point_id bigint, ap_name text, owner_id bigint, template_id text, stack_size bigint, initial_stack_size bigint, item_price bigint, quality_level bigint, durability_cur real, durability_max real, dynamic_stats jsonb)
 LANGUAGE plpgsql
AS $function$
DECLARE
BEGIN
	RETURN query
		SELECT ord.id, ord.revision, ord.expiration_time, ord.access_point_id, ap.name, ord.owner_id, item.template_id, item.stack_size, sord.initial_stack_size, ord.item_price, ord.quality_level, ord.durability_cur, ord.durability_max, item.stats
		FROM dune_exchange_orders ord
		JOIN dune_exchange_sell_orders sord ON (ord.id = sord.order_id)
		JOIN items item ON (ord.item_id = item.id)
		JOIN dune_exchange_accesspoints ap ON (ord.access_point_id = ap.id)
		WHERE ord.exchange_id = in_exchange_id AND ord.template_id = ANY(in_template_ids)
		FOR SHARE;
END
$function$
