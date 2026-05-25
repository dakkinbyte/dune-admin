-- dune_exchange_update_recurring_sell_order(in_exchange_id bigint, in_expiration_time bigint, in_access_point_id bigint, in_owner_id bigint, in_item_id bigint, in_increment bigint, in_max_count bigint, in_category_mask integer, in_category_depth smallint, in_durability_cur real, in_durability_max real, in_item_price bigint, in_wear_normalized_item_price bigint, in_quality_level bigint) -> bigint
-- oid: 58256  kind: FUNCTION  category: exchange

CREATE OR REPLACE FUNCTION dune.dune_exchange_update_recurring_sell_order(in_exchange_id bigint, in_expiration_time bigint, in_access_point_id bigint, in_owner_id bigint, in_item_id bigint, in_increment bigint, in_max_count bigint, in_category_mask integer, in_category_depth smallint, in_durability_cur real, in_durability_max real, in_item_price bigint, in_wear_normalized_item_price bigint, in_quality_level bigint)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	exchange_inventory_id BIGINT;
	new_item_id BIGINT;
	item_stack_size BIGINT;
	new_order_id BIGINT;
	item_template_id TEXT;
	old_count BIGINT;
	new_count BIGINT;
	delta_count BIGINT;
BEGIN
	LOCK TABLE dune_exchange_orders, items IN ROW EXCLUSIVE MODE;

	SELECT INTO exchange_inventory_id get_exchange_inventory_id(in_exchange_id);

	IF exchange_inventory_id IS NULL THEN
		RETURN 0;
	END IF;

	SELECT INTO STRICT item_template_id template_id FROM items WHERE id = in_item_id FOR SHARE;

	SELECT INTO new_order_id, new_item_id ord.id, ord.item_id
	FROM dune_exchange_orders ord
	JOIN dune_exchange_sell_orders sord ON (ord.id = sord.order_id)
	WHERE ord.is_npc_order = TRUE AND ord.exchange_id = in_exchange_id AND ord.access_point_id = in_access_point_id AND ord.template_id = item_template_id AND ord.item_price = in_item_price AND ord.quality_level = in_quality_level
	FOR SHARE;

	IF new_order_id IS NULL THEN
		INSERT INTO dune_exchange_orders(exchange_id, access_point_id, owner_id, is_npc_order, expiration_time, template_id, durability_cur, durability_max, category_mask, category_depth, item_price, quality_level)
		VALUES(in_exchange_id, in_access_point_id, in_owner_id, TRUE, in_expiration_time, item_template_id, in_durability_cur, in_durability_max, in_category_mask, in_category_depth, in_item_price, in_quality_level)
		RETURNING id INTO new_order_id;

		INSERT INTO dune_exchange_sell_orders(order_id, initial_stack_size, wear_normalized_price) VALUES(new_order_id, new_count, in_wear_normalized_item_price);
		SELECT INTO new_item_id move_inventory_item(in_item_id, exchange_inventory_id, new_order_id, in_increment);

		IF new_item_id IS NULL THEN
			DELETE FROM dune_exchange_orders WHERE id = new_order_id;
			RETURN 0;
		END IF;

		UPDATE dune_exchange_orders SET item_id = new_item_id WHERE id = new_order_id;

		RETURN in_increment;
	ELSE
		UPDATE dune_exchange_orders SET expiration_time = in_expiration_time WHERE id=new_order_id;
		SELECT INTO STRICT old_count stack_size FROM items WHERE id = new_item_id FOR SHARE;
		new_count = old_count + in_increment;
		IF new_count > in_max_count THEN new_count = in_max_count; END IF;
		IF new_count != old_count THEN
			delta_count = new_count - old_count;
			SELECT INTO new_item_id merge_or_move_inventory_item(in_item_id, exchange_inventory_id, new_order_id, delta_count);
			RETURN delta_count;
		END IF;

		RETURN 0;
	END IF;
END $function$
