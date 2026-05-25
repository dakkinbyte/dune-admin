-- decrypt_user_data(in_encrypted_data bytea) -> text
-- oid: 58197  kind: FUNCTION  category: encryption

CREATE OR REPLACE FUNCTION dune.decrypt_user_data(in_encrypted_data bytea)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$select convert_from(in_encrypted_data, 'utf8');$function$
