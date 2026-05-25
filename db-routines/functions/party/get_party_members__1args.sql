-- get_party_members(in_party_id bigint) -> TABLE(player_id bigint, fls_id text, party_id bigint)
-- oid: 58325  kind: FUNCTION  category: party

CREATE OR REPLACE FUNCTION dune.get_party_members(in_party_id bigint)
 RETURNS TABLE(player_id bigint, fls_id text, party_id bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY
	SELECT pm.player_id, acc.user, pm.party_id
	FROM party_members pm
	LEFT JOIN player_state ps ON ps.player_controller_id = pm.player_id
	LEFT JOIN accounts acc ON acc.id = ps.account_id
	WHERE pm.party_id = in_party_id;
END
$function$
