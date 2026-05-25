-- clean_stock_for_player(in_player_id bigint) -> void
-- oid: 58168  kind: FUNCTION  category: stock_vendor

CREATE OR REPLACE FUNCTION dune.clean_stock_for_player(in_player_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM vendor_stock_cycle WHERE player_id = in_player_id;
	DELETE FROM vendor_stock_state WHERE player_id = in_player_id;
END
$function$
