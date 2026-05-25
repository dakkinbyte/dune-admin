-- get_all_demo_players() -> TABLE(fls_ids text)
-- oid: 58273  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_all_demo_players()
 RETURNS TABLE(fls_ids text)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY SELECT fls_id
	FROM demo_users
    WHERE demo_playtime_seconds IS NOT NULL;
END
$function$
