-- debug_add_test_table_data(in_entry text) -> void
-- oid: 58187  kind: FUNCTION  category: debug

CREATE OR REPLACE FUNCTION dune.debug_add_test_table_data(in_entry text)
 RETURNS void
 LANGUAGE sql
AS $function$
	insert into debug_test_table("entry") VALUES (in_entry);
$function$
