-- player_purchased_item_from_vendor(in_vendor_id text, in_player_id bigint, in_template_id text, in_amount_bought integer) -> void
-- oid: 58494  kind: FUNCTION  category: inventory

CREATE OR REPLACE FUNCTION dune.player_purchased_item_from_vendor(in_vendor_id text, in_player_id bigint, in_template_id text, in_amount_bought integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	-- Add/update stock
	IF NOT EXISTS
		( SELECT * FROM vendor_stock_state
		WHERE vendor_id = in_vendor_id and player_id = in_player_id AND template_id = in_template_id)
	THEN
		INSERT INTO vendor_stock_state(vendor_id, player_id, template_id, amount_bought) VALUES(in_vendor_id, in_player_id, in_template_id, in_amount_bought);
	ELSE
		UPDATE vendor_stock_state SET amount_bought = amount_bought + in_amount_bought
		WHERE vendor_id = in_vendor_id and player_id = in_player_id AND template_id = in_template_id;
	END IF;
END
$function$
