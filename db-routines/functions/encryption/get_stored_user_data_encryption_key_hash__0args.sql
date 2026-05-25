-- get_stored_user_data_encryption_key_hash() -> bytea
-- oid: 58353  kind: FUNCTION  category: encryption

CREATE OR REPLACE FUNCTION dune.get_stored_user_data_encryption_key_hash()
 RETURNS bytea
 LANGUAGE sql
 IMMUTABLE
AS $function$select null::bytea;$function$
