-- clean_stock_for_vendors(in_vendor_ids text[]) -> void
-- oid: 58169  kind: FUNCTION  category: stock_vendor

CREATE OR REPLACE FUNCTION dune.clean_stock_for_vendors(in_vendor_ids text[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM vendor_stock_cycle WHERE vendor_id = ANY(in_vendor_ids);
	DELETE FROM vendor_stock_state WHERE vendor_id = ANY(in_vendor_ids);
END
$function$
