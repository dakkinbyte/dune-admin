-- debug_raise_exception(in_exception text, in_notices text[]) -> void
-- oid: 58191  kind: FUNCTION  category: debug

CREATE OR REPLACE FUNCTION dune.debug_raise_exception(in_exception text, in_notices text[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	perform debug_raise_notices(in_notices);
	RAISE EXCEPTION '%', in_exception;
END;
$function$
