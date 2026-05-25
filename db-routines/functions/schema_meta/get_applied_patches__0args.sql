-- get_applied_patches() -> SETOF text
-- oid: 58285  kind: FUNCTION  category: schema_meta

CREATE OR REPLACE FUNCTION dune.get_applied_patches()
 RETURNS SETOF text
 LANGUAGE sql
AS $function$
	select "name" from applied_patches order by "date";
$function$
