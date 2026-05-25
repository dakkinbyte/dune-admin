-- dune_exchange_modify_user_solari_balance(in_controller_id bigint, in_solari_delta bigint) -> void
-- oid: 58248  kind: FUNCTION  category: currency

CREATE OR REPLACE FUNCTION dune.dune_exchange_modify_user_solari_balance(in_controller_id bigint, in_solari_delta bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	user_id BIGINT;
	current_balance BIGINT;
	new_balance BIGINT;
	delta_balance BIGINT;
	fls_id TEXT;
	function_oid oid;
BEGIN
	SELECT INTO user_id dune_exchange_get_user_id(in_controller_id);
	SELECT INTO current_balance balance from player_virtual_currency_balances WHERE currency_id = get_solaris_id() AND player_controller_id = in_controller_id;

	IF current_balance < 0 THEN
		SELECT acc."user"
		INTO fls_id
		FROM accounts acc
		JOIN player_state ps on ps.account_id = acc.id
		WHERE ps.player_controller_id = in_controller_id
		LIMIT 1;

		PERFORM log_cheating(COALESCE(fls_id, in_controller_id::text), 'exchange_negative_solaris');
		UPDATE player_virtual_currency_balances SET balance = 0 WHERE currency_id = get_solaris_id() AND player_controller_id = in_controller_id;
		current_balance = 0;
	END IF;

	delta_balance = in_solari_delta;
	IF current_balance < in_solari_delta THEN
		delta_balance = current_balance;
	END IF;

	UPDATE dune_exchange_users SET solari_balance = solari_balance + delta_balance WHERE id = user_id;
	
	UPDATE player_virtual_currency_balances SET balance = balance - delta_balance WHERE currency_id = get_solaris_id() AND player_controller_id = in_controller_id RETURNING player_virtual_currency_balances.balance INTO new_balance;

	GET DIAGNOSTICS function_oid = PG_ROUTINE_OID;
	PERFORM log_event_solaris(function_oid, 'update_solaris', in_controller_id, new_balance, delta_balance);
END $function$
