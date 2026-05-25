-- dune_exchange_fulfill_sell_order(in_exchange_id bigint, in_max_orders_per_player integer, in_purchased_completion_type integer, in_sold_completion_type integer, in_instigator_id bigint, in_order_id bigint, in_order_revision bigint, in_dst_inventory_id bigint, in_dst_index bigint, in_count bigint, in_solaris_fee bigint, in_purge_time bigint) -> dune.duneexchangefulfillsellorderresult
-- oid: 58244  kind: FUNCTION  category: exchange

CREATE OR REPLACE FUNCTION dune.dune_exchange_fulfill_sell_order(in_exchange_id bigint, in_max_orders_per_player integer, in_purchased_completion_type integer, in_sold_completion_type integer, in_instigator_id bigint, in_order_id bigint, in_order_revision bigint, in_dst_inventory_id bigint, in_dst_index bigint, in_count bigint, in_solaris_fee bigint, in_purge_time bigint)
 RETURNS dune.duneexchangefulfillsellorderresult
 LANGUAGE plpgsql
AS $function$
DECLARE
	exchange_inventory_id BIGINT;
	order_access_point_id BIGINT;
	seller_actor_id BIGINT;
	seller_user_id BIGINT;
	buyer_user_id BIGINT;
	user_solari_balance BIGINT;
	per_item_price BIGINT;
	total_cost BIGINT;
	order_revision BIGINT;
	order_item_id BIGINT;
	order_is_npc_order BOOLEAN;
	order_category_mask INT;
	order_category_depth SMALLINT;
	item_template_id TEXT;
	item_durability_cur REAL;
	item_durability_max REAL;
	storage_order_id BIGINT;
	log_order_id BIGINT;
	result DuneExchangeFulfillSellOrderResult;

BEGIN
	result.item_id = 0;
	SELECT INTO result.order_slots_used get_dune_exchange_used_order_slots(in_instigator_id);

	IF result.order_slots_used >= in_max_orders_per_player THEN
		RETURN result;
	END IF;

	SELECT INTO exchange_inventory_id get_exchange_inventory_id(in_exchange_id);
	SELECT INTO buyer_user_id dune_exchange_get_user_id(in_instigator_id);

	BEGIN
		SELECT INTO STRICT user_solari_balance solari_balance FROM dune_exchange_users WHERE id = buyer_user_id FOR UPDATE;
		SELECT INTO STRICT
			order_revision,
			order_access_point_id,
			order_item_id,
			item_template_id,
			item_durability_cur,
			item_durability_max,
			seller_actor_id,
			order_category_mask,
			order_category_depth,
			order_is_npc_order,
			per_item_price

			ord.revision,
			ord.access_point_id,
			ord.item_id,
			ord.template_id,
			ord.durability_cur,
			ord.durability_max,
			ord.owner_id,
			ord.category_mask,
			ord.category_depth,
			ord.is_npc_order,
			ord.item_price
		FROM
			dune_exchange_orders ord
		JOIN dune_exchange_sell_orders sord ON (ord.id = sord.order_id)
		WHERE
			id = in_order_id AND revision = in_order_revision
		FOR UPDATE;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN RETURN result;
	END;

	IF order_revision != in_order_revision THEN
		RETURN result;
	END IF;

	IF NOT order_is_npc_order THEN
		SELECT INTO seller_user_id dune_exchange_get_user_id(seller_actor_id);
	END IF;
	total_cost = per_item_price * in_count + in_solaris_fee;

	IF total_cost > user_solari_balance THEN
		RETURN result;
	END IF;

	IF in_dst_inventory_id IS NULL THEN
		-- Item is to be transferred to exchange storage rather than an external inventory. Make a record for it.
		INSERT INTO dune_exchange_orders(exchange_id, access_point_id, owner_id, template_id, expiration_time, durability_cur, durability_max, item_price, category_mask, category_depth)
			VALUES(in_exchange_id, order_access_point_id, in_instigator_id, item_template_id, in_purge_time, item_durability_cur, item_durability_max, per_item_price, order_category_mask, order_category_depth)
			RETURNING id INTO storage_order_id;

		INSERT INTO dune_exchange_fulfilled_orders(order_id, completion_type, stack_size, original_order_id)
			VALUES(storage_order_id, in_purchased_completion_type, in_count, in_order_id);

		in_dst_inventory_id = exchange_inventory_id;
		in_dst_index = storage_order_id;
	END IF;

	UPDATE dune_exchange_orders SET item_id = NULL WHERE id = in_order_id;

	SELECT INTO result.item_id move_inventory_item(order_item_id, in_dst_inventory_id, in_dst_index, in_count);

	IF result.item_id IS NULL THEN
		IF storage_order_id IS NOT NULL THEN
			DELETE FROM dune_exchange_orders WHERE id = storage_order_id;
		END IF;
		RETURN result;
	END IF;

	-- Create an entry for the fulfilled orders log.
	SELECT INTO log_order_id order_id FROM dune_exchange_fulfilled_orders where source_order_id = in_order_id FOR SHARE;

	IF log_order_id IS NOT NULL THEN
		UPDATE dune_exchange_orders SET expiration_time = in_purge_time, revision = revision + 1 WHERE id = log_order_id;
		UPDATE dune_exchange_fulfilled_orders SET stack_size = stack_size + in_count WHERE order_id = log_order_id;
	ELSE
		INSERT INTO dune_exchange_orders(exchange_id, access_point_id, owner_id, template_id, expiration_time, durability_cur, durability_max, item_price, category_mask, category_depth)
			VALUES(in_exchange_id, order_access_point_id, seller_actor_id, item_template_id, in_purge_time, item_durability_cur, item_durability_max, per_item_price, order_category_mask, order_category_depth) RETURNING id INTO log_order_id;

		INSERT INTO dune_exchange_fulfilled_orders(order_id, source_order_id, completion_type, stack_size, original_order_id)
			VALUES(log_order_id, in_order_id, in_sold_completion_type, in_count, in_order_id);
	END IF;

	UPDATE dune_exchange_users SET solari_balance = solari_balance - total_cost WHERE id = buyer_user_id;
	-- If the new ID is equal to the old ID the item/stack was moved rather than split and the order is now empty
	IF result.item_id = order_item_id THEN
		DELETE FROM dune_exchange_orders WHERE id = in_order_id;
	ELSE
		UPDATE dune_exchange_orders SET item_id = order_item_id, revision = revision + 1 WHERE id = in_order_id; -- Item was split. Restore reference to remaining items.
	END IF;
	-- If the item was transferred to exchange storage rather than an external inventory, update the record with the item ID.
	IF storage_order_id IS NOT NULL THEN
		UPDATE dune_exchange_orders SET item_id = result.item_id WHERE id = storage_order_id;
	END IF;

	result.order_slots_used = result.order_slots_used + 1;

	RETURN result;
END $function$
