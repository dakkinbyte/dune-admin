-- get_character_transfer_related_items(in_fls_id text) -> jsonb
-- oid: 58293  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune.get_character_transfer_related_items(in_fls_id text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
BEGIN

RETURN (
	WITH acct AS (
		SELECT id
		FROM accounts
		WHERE "user" = in_FLS_ID
		LIMIT 1
	)
	SELECT jsonb_build_object(
		'items', COALESCE((
			SELECT jsonb_agg(jsonb_build_object('name', sub.template_id, 'amount', sub.amount))
			FROM (
			SELECT i.template_id, SUM(i.stack_size) AS amount
			FROM inventories inv
			JOIN items i ON i.inventory_id = inv.id
			JOIN player_state ps ON inv.actor_id = ps.player_pawn_id
			WHERE ps.account_id = acct.id AND (
				(inv.inventory_type = 0 AND i.template_id = 'SolarisCoin') OR
				(i.template_id IN ('BaseBackupTool', 'VehicleBackupTool'))
				)
			GROUP BY i.template_id
			) sub
		), '[]'::jsonb),
		'coin_balance', COALESCE((
            SELECT vc.balance from player_virtual_currency_balances vc
            JOIN player_state ps ON ps.account_id = acct.id
            WHERE vc.currency_id = get_solaris_id()
            AND vc.player_controller_id = ps.player_controller_id
			LIMIT 1
		), 0)
	)
	FROM acct
);

END
$function$
