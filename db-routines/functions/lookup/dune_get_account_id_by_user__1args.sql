-- dune_get_account_id_by_user(in_user text) -> bigint
-- oid: 58257  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.dune_get_account_id_by_user(in_user text)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	account_id BIGINT;
BEGIN
	SELECT INTO account_id id FROM accounts WHERE "user"=in_user;
	RETURN account_id;
END $function$
