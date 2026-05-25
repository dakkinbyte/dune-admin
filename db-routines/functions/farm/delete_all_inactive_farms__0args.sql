-- delete_all_inactive_farms() -> void
-- oid: 58205  kind: FUNCTION  category: farm

CREATE OR REPLACE FUNCTION dune.delete_all_inactive_farms()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM farm_state WHERE server_id NOT IN (SELECT * FROM active_server_ids);
END
$function$
