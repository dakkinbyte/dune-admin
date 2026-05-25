-- clean_vendors_older_than_timestamp(in_reference_timestamp bigint) -> void
-- oid: 58170  kind: FUNCTION  category: stock_vendor

CREATE OR REPLACE FUNCTION dune.clean_vendors_older_than_timestamp(in_reference_timestamp bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
   vendors_to_delete TEXT[];
BEGIN
	SELECT array_agg(vendor_id) INTO vendors_to_delete FROM vendor_stock_cycle WHERE last_interacted_timestamp <= in_reference_timestamp;
	DELETE FROM vendor_stock_cycle WHERE vendor_id = ANY(vendors_to_delete);
	DELETE FROM vendor_stock_state WHERE vendor_id = ANY(vendors_to_delete);
END
$function$
