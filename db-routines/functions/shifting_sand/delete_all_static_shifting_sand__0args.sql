-- delete_all_static_shifting_sand() -> void
-- oid: 58207  kind: FUNCTION  category: shifting_sand

CREATE OR REPLACE FUNCTION dune.delete_all_static_shifting_sand()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	TRUNCATE shiftingsands_data;
END $function$
