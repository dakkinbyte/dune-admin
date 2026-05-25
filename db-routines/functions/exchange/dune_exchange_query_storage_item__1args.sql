-- dune_exchange_query_storage_item(in_order_id bigint) -> TABLE(completion_type integer, id bigint, revision bigint, expiration_time bigint, access_point_id bigint, ap_name text, owner_id bigint, item_id bigint, template_id text, stack_size bigint, item_price bigint, quality_level bigint, durability_cur real, durability_max real, dynamic_stats jsonb)
-- oid: 58250  kind: FUNCTION  category: exchange

CREATE OR REPLACE FUNCTION dune.dune_exchange_query_storage_item(in_order_id bigint)
 RETURNS TABLE(completion_type integer, id bigint, revision bigint, expiration_time bigint, access_point_id bigint, ap_name text, owner_id bigint, item_id bigint, template_id text, stack_size bigint, item_price bigint, quality_level bigint, durability_cur real, durability_max real, dynamic_stats jsonb)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY
		SELECT sord.completion_type, ord.id, ord.revision, ord.expiration_time, ord.access_point_id, ap.name, ord.owner_id, ord.item_id, ord.template_id, sord.stack_size, ord.item_price, ord.quality_level, ord.durability_cur, ord.durability_max, item.stats
		FROM dune_exchange_orders ord
		JOIN dune_exchange_fulfilled_orders sord ON (ord.id = sord.order_id)
		JOIN dune_exchange_accesspoints ap ON (ord.access_point_id = ap.id)
		LEFT JOIN items item ON ord.item_id = item.id
		WHERE ord.id = in_order_id;
END; $function$
