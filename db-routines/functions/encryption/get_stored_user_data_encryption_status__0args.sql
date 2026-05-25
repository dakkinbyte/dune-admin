-- get_stored_user_data_encryption_status() -> dune.userdataencryptionstatus
-- oid: 58354  kind: FUNCTION  category: encryption

CREATE OR REPLACE FUNCTION dune.get_stored_user_data_encryption_status()
 RETURNS dune.userdataencryptionstatus
 LANGUAGE sql
 IMMUTABLE
AS $function$select 'Disabled'::UserDataEncryptionStatus$function$
