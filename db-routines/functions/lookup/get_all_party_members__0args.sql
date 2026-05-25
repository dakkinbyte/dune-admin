-- get_all_party_members() -> TABLE(player_id bigint, fls_id text, party_id bigint)
-- oid: 58279  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_all_party_members()
 RETURNS TABLE(player_id bigint, fls_id text, party_id bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY
	SELECT pm.player_id, acc.user, pm.party_id
	FROM party_members pm
	LEFT JOIN player_state ps ON ps.player_controller_id = pm.player_id
	LEFT JOIN accounts acc ON acc.id = ps.account_id;
END
$function$
