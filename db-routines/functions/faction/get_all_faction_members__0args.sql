-- get_all_faction_members() -> TABLE(player_id bigint, fls_id text, faction_id smallint)
-- oid: 58274  kind: FUNCTION  category: faction

CREATE OR REPLACE FUNCTION dune.get_all_faction_members()
 RETURNS TABLE(player_id bigint, fls_id text, faction_id smallint)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY
	SELECT ps.player_controller_id as player_id, acc.user as fls_id, f.faction_id
	FROM accounts acc
	LEFT JOIN player_state ps ON acc.id = ps.account_id
	RIGHT JOIN player_faction f ON ps.player_controller_id = f.actor_id;
END
$function$
