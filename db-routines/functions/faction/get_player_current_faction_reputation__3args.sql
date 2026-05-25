-- get_player_current_faction_reputation(in_actor_id bigint, OUT out_faction_id smallint, OUT out_reputation_amount integer) -> record
-- oid: 58332  kind: FUNCTION  category: faction

CREATE OR REPLACE FUNCTION dune.get_player_current_faction_reputation(in_actor_id bigint, OUT out_faction_id smallint, OUT out_reputation_amount integer)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
	SELECT
		pf.faction_id,
		COALESCE(pfr.reputation_amount, 0)
	INTO out_faction_id, out_reputation_amount
	FROM player_faction pf
	LEFT JOIN player_faction_reputation pfr
		ON pfr.actor_id = pf.actor_id AND pfr.faction_id = pf.faction_id
	WHERE pf.actor_id = in_actor_id
	limit 1;
END
$function$
