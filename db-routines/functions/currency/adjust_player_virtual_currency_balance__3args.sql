-- adjust_player_virtual_currency_balance(in_controller_id bigint, in_currency_id smallint, in_delta bigint) -> bigint
-- oid: 58129  kind: FUNCTION  category: currency

CREATE OR REPLACE FUNCTION dune.adjust_player_virtual_currency_balance(in_controller_id bigint, in_currency_id smallint, in_delta bigint)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	current_balance BIGINT;
	current_delta BIGINT;
	new_delta BIGINT;
	fls_id TEXT;
	function_oid oid;
BEGIN
	SELECT INTO current_balance balance from player_virtual_currency_balances WHERE player_controller_id = in_controller_id AND currency_id = in_currency_id;
	INSERT INTO player_virtual_currency_balances("player_controller_id", "currency_id", "balance")
		VALUES (in_controller_id, in_currency_id, in_delta)
		ON CONFLICT (player_controller_id, currency_id) DO UPDATE SET balance = (player_virtual_currency_balances.balance + in_delta)
		RETURNING balance INTO current_balance;

    IF in_currency_id = get_solaris_id() THEN
	    GET DIAGNOSTICS function_oid = PG_ROUTINE_OID;
	    PERFORM log_event_solaris(function_oid, 'update_solaris', in_controller_id, current_balance, in_delta);
    END IF;

	current_delta = 0;
	IF current_balance < 0 THEN
		SELECT acc."user"
		INTO fls_id
		FROM accounts acc
		JOIN player_state ps on ps.account_id = acc.id
		WHERE ps.account_id = in_player_id
		LIMIT 1;

		PERFORM log_cheating(COALESCE(fls_id, in_player_id::text), 'negative_solaris');

		INSERT INTO player_virtual_currency_balances("player_controller_id", "currency_id", "balance")
			VALUES (in_controller_id, in_currency_id, 0)
			ON CONFLICT (player_controller_id, currency_id) DO UPDATE SET balance = 0;
		current_delta = current_balance;
	END IF;

	new_delta = in_delta + current_delta;
	RETURN new_delta;
END;
$function$
