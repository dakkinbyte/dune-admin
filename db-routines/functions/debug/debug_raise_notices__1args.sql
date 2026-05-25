-- debug_raise_notices(in_notices text[]) -> void
-- oid: 58192  kind: FUNCTION  category: debug

CREATE OR REPLACE FUNCTION dune.debug_raise_notices(in_notices text[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	IF array_length(in_notices, 1) IS NOT NULL THEN
		FOR i IN 0..array_length(in_notices, 1)-1
		LOOP
			RAISE NOTICE '%', in_notices[i];
		END LOOP;
	END IF;
END;
$function$
