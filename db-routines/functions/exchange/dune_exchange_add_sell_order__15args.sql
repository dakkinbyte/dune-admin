-- dune_exchange_add_sell_order(in_exchange_id bigint, in_access_point_id bigint, in_owner_id bigint, in_max_orders_per_player integer, in_expiration_time bigint, in_item_id bigint, in_count bigint, in_category_mask integer, in_category_depth smallint, in_durability_cur real, in_durability_max real, in_item_price bigint, in_wear_normalized_item_price bigint, in_quality_level bigint, in_solari_cost bigint) -> dune.duneexchangeaddsellorderresult
-- oid: 58241  kind: FUNCTION  category: exchange

CREATE OR REPLACE FUNCTION dune.dune_exchange_add_sell_order(in_exchange_id bigint, in_access_point_id bigint, in_owner_id bigint, in_max_orders_per_player integer, in_expiration_time bigint, in_item_id bigint, in_count bigint, in_category_mask integer, in_category_depth smallint, in_durability_cur real, in_durability_max real, in_item_price bigint, in_wear_normalized_item_price bigint, in_quality_level bigint, in_solari_cost bigint)
 RETURNS dune.duneexchangeaddsellorderresult
 LANGUAGE plpgsql
AS $function$
DECLARE
	exchange_inventory_id BIGINT;
	user_id BIGINT;
	new_item_id BIGINT;
	item_template_id TEXT;
	result DuneExchangeAddSellOrderResult;
	fls_id TEXT;
BEGIN
	result.order_id = 0;
	SELECT INTO result.order_slots_used get_dune_exchange_used_order_slots(in_owner_id);

	IF result.order_slots_used >= in_max_orders_per_player THEN
		RETURN result;
	END IF;

	PERFORM * from dune_exchange_orders where item_id = in_item_id;
	IF FOUND THEN
	    -- Debug logging
        SELECT acc."user"
            INTO fls_id
            FROM accounts acc
			JOIN player_state ps on ps.account_id = acc.id
			WHERE ps.player_controller_id = in_owner_id
            LIMIT 1;
		PERFORM log_cheating(fls_id, 'exchange_order_dupe');
        RAISE WARNING 'Trying to dupe exchange sell orders FLS: %', fls_id;
		RETURN result;
	END IF;

	SELECT INTO user_id dune_exchange_get_user_id(in_owner_id);
	SELECT INTO exchange_inventory_id get_exchange_inventory_id(in_exchange_id);

	IF exchange_inventory_id IS NULL THEN
		RETURN result;
	END IF;

	UPDATE dune_exchange_users SET solari_balance = solari_balance - in_solari_cost WHERE id = user_id AND solari_balance >= in_solari_cost;

	IF NOT FOUND THEN
		RETURN result;
	END IF;

	SELECT INTO STRICT item_template_id template_id FROM items WHERE id = in_item_id FOR UPDATE;
	INSERT INTO dune_exchange_orders(exchange_id, access_point_id, owner_id, expiration_time, template_id, durability_cur, durability_max, category_mask, category_depth, item_price, quality_level)
	VALUES(in_exchange_id, in_access_point_id, in_owner_id, in_expiration_time, item_template_id, in_durability_cur, in_durability_max, in_category_mask, in_category_depth, in_item_price, in_quality_level)
	RETURNING id INTO result.order_id;

	INSERT INTO dune_exchange_sell_orders(order_id, initial_stack_size, wear_normalized_price) VALUES(result.order_id, in_count, in_wear_normalized_item_price);
	SELECT INTO new_item_id move_inventory_item(in_item_id, exchange_inventory_id, result.order_id, in_count);

	IF new_item_id IS NULL THEN
		RAISE EXCEPTION 'Failed to move inventory item %', in_item_id;
	END IF;

	UPDATE dune_exchange_orders SET item_id = new_item_id WHERE id = result.order_id;

	result.order_slots_used = result.order_slots_used + 1;

	RETURN result;
END $function$
