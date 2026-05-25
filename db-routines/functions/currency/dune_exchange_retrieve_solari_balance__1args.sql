-- dune_exchange_retrieve_solari_balance(in_owner_id bigint) -> bigint
-- oid: 58253  kind: FUNCTION  category: currency

CREATE OR REPLACE FUNCTION dune.dune_exchange_retrieve_solari_balance(in_owner_id bigint)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	current_balance BIGINT;
	fls_id TEXT;
BEGIN
	SELECT INTO current_balance solari_balance from dune_exchange_users WHERE owner_id = in_owner_id LIMIT 1;

	IF current_balance < 0 THEN
		SELECT acc."user"
		INTO fls_id
		FROM accounts acc
		JOIN player_state ps on ps.account_id = acc.id
		WHERE ps.player_controller_id = in_owner_id
		LIMIT 1;

		PERFORM log_cheating(COALESCE(fls_id, in_owner_id::text), 'exchange_negative_solaris');

		UPDATE dune_exchange_users SET solari_balance = 0 WHERE owner_id = in_owner_id;
	END IF;
	RETURN (SELECT solari_balance FROM dune_exchange_users WHERE owner_id = in_owner_id LIMIT 1);
END; $function$
