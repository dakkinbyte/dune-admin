-- interact_get_vendor_items_bought_from_player(in_vendor_id text, in_player_id bigint, in_current_cycle_start_timestamp bigint) -> TABLE(out_template_id text, out_amount_bought integer)
-- oid: 58390  kind: FUNCTION  category: stock_vendor

CREATE OR REPLACE FUNCTION dune.interact_get_vendor_items_bought_from_player(in_vendor_id text, in_player_id bigint, in_current_cycle_start_timestamp bigint)
 RETURNS TABLE(out_template_id text, out_amount_bought integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
   player_timestamp BIGINT;
BEGIN
	-- Clean items bought by player if the vendor's cycle was reset since the last time they interacted with it
	IF EXISTS
		(SELECT * FROM vendor_stock_cycle
		WHERE vendor_id = in_vendor_id AND player_id = in_player_id AND last_interacted_timestamp < in_current_cycle_start_timestamp)
	THEN
		DELETE FROM vendor_stock_state WHERE vendor_id = in_vendor_id AND player_id = in_player_id;	
	END IF;
	
	PERFORM update_vendor_timestamp_for_player(in_vendor_id, in_player_id, in_current_cycle_start_timestamp);
	
	RETURN QUERY
    SELECT template_id, amount_bought FROM vendor_stock_state WHERE vendor_id = in_vendor_id AND player_id = in_player_id;
END
$function$
