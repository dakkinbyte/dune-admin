-- set_account_as_takeoverable(in_user_id text, in_new_user_id text) -> void
-- oid: 58587  kind: FUNCTION  category: takeover

CREATE OR REPLACE FUNCTION dune.set_account_as_takeoverable(in_user_id text, in_new_user_id text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE accounts SET "user"=in_new_user_id, takeoverable=TRUE WHERE "user"=in_user_id;
END; $function$
