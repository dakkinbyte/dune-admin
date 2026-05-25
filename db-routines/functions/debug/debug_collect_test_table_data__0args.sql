-- debug_collect_test_table_data() -> SETOF text
-- oid: 58188  kind: FUNCTION  category: debug

CREATE OR REPLACE FUNCTION dune.debug_collect_test_table_data()
 RETURNS SETOF text
 LANGUAGE sql
AS $function$
	select entry from debug_test_table;
$function$
