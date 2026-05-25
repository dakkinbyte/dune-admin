-- debug_reset_test_table() -> void
-- oid: 58193  kind: FUNCTION  category: debug

CREATE OR REPLACE FUNCTION dune.debug_reset_test_table()
 RETURNS void
 LANGUAGE sql
AS $function$
	truncate debug_test_table;
$function$
