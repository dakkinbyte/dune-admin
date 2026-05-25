-- get_stored_user_data_encryption_taint_xmax() -> bigint
-- oid: 58355  kind: FUNCTION  category: encryption

CREATE OR REPLACE FUNCTION dune.get_stored_user_data_encryption_taint_xmax()
 RETURNS bigint
 LANGUAGE sql
 IMMUTABLE
AS $function$select null::int8;$function$
