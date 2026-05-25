-- update_vendor_timestamp_for_player(in_vendor_id text, in_player_id bigint, in_timestamp bigint) -> void
-- oid: 58643  kind: FUNCTION  category: stock_vendor

CREATE OR REPLACE FUNCTION dune.update_vendor_timestamp_for_player(in_vendor_id text, in_player_id bigint, in_timestamp bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	IF NOT EXISTS
		( SELECT * FROM vendor_stock_cycle
		WHERE vendor_id = in_vendor_id AND player_id = in_player_id)
	THEN
		INSERT INTO vendor_stock_cycle(vendor_id, player_id, last_interacted_timestamp) VALUES(in_vendor_id, in_player_id, in_timestamp);
	ELSE
		UPDATE vendor_stock_cycle
		SET last_interacted_timestamp = in_timestamp
		WHERE vendor_id = in_vendor_id AND player_id = in_player_id;
	END IF;
END
$function$
