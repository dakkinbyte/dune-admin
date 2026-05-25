-- encrypt_user_data(in_data text) -> bytea
-- oid: 58259  kind: FUNCTION  category: encryption

CREATE OR REPLACE FUNCTION dune.encrypt_user_data(in_data text)
 RETURNS bytea
 LANGUAGE sql
 IMMUTABLE
AS $function$select convert_to(in_data, 'utf8')$function$
