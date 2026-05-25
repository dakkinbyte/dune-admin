-- debug_echo(in_text text, in_notices text[]) -> text
-- oid: 58189  kind: FUNCTION  category: debug

CREATE OR REPLACE FUNCTION dune.debug_echo(in_text text, in_notices text[])
 RETURNS text
 LANGUAGE plpgsql
AS $function$
BEGIN
	perform debug_raise_notices(in_notices);
	return in_text;
END;
$function$
