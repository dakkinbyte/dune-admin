-- get_player_virtual_currency_balances(in_controller_id bigint) -> TABLE(out_currency_id smallint, out_currency_balance bigint)
-- oid: 58345  kind: FUNCTION  category: currency

CREATE OR REPLACE FUNCTION dune.get_player_virtual_currency_balances(in_controller_id bigint)
 RETURNS TABLE(out_currency_id smallint, out_currency_balance bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
	return query (
		with currencies as (select currency_id, balance from player_virtual_currency_balances where player_controller_id = in_controller_id),
		bad_currencies as (select * from currencies where balance < 0),
		target_account_id as (select account_id from player_state where player_controller_id = in_controller_id limit 1),
		report_cheaters as (select currency_id, flag_player_as_cheater(target_account_id.account_id, 'negative_solaris') from bad_currencies, target_account_id),
		fix_bad_currencies as (update player_virtual_currency_balances set balance = 0 from report_cheaters where player_controller_id = in_controller_id and player_virtual_currency_balances.currency_id = report_cheaters.currency_id)
		select currency_id, balance from currencies
	);
END;
$function$
