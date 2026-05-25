-- get_schema_version() -> integer
-- oid: 58350  kind: FUNCTION  category: schema_meta

CREATE OR REPLACE FUNCTION dune.get_schema_version()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
	return 999999;
END;
$function$
