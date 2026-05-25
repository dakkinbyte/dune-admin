-- dune_exchange_get_user_id(in_owner_id bigint) -> bigint
-- oid: 58247  kind: FUNCTION  category: exchange

CREATE OR REPLACE FUNCTION dune.dune_exchange_get_user_id(in_owner_id bigint)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	new_user_id BIGINT;
	user_id BIGINT;
BEGIN
	INSERT INTO dune_exchange_users(owner_id) VALUES(in_owner_id) ON CONFLICT DO NOTHING RETURNING id INTO new_user_id;
	SELECT INTO user_id COALESCE(new_user_id, id) FROM dune_exchange_users WHERE owner_id = in_owner_id;

	return user_id;
END $function$
