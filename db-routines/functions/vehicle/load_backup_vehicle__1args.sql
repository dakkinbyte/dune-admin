-- load_backup_vehicle(in_account_id bigint) -> TABLE(out_id bigint, out_class text, out_customization_id text)
-- oid: 58439  kind: FUNCTION  category: vehicle

CREATE OR REPLACE FUNCTION dune.load_backup_vehicle(in_account_id bigint)
 RETURNS TABLE(out_id bigint, out_class text, out_customization_id text)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY
		SELECT a.id, a.class, bv.customization_id
		FROM actors a
		JOIN backup_vehicles bv on a.id = bv.vehicle_id 
		WHERE bv.account_id = in_account_id
		LIMIT 1;
END
$function$
