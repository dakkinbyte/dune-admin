-- get_solaris_id() -> smallint
-- oid: 58351  kind: FUNCTION  category: currency

CREATE OR REPLACE FUNCTION dune.get_solaris_id()
 RETURNS smallint
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
DECLARE
    solaris_id CONSTANT SMALLINT := 0;
BEGIN
    return solaris_id;
END
$function$
