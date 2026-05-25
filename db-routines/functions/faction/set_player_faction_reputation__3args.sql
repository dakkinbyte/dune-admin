-- set_player_faction_reputation(in_actor_id bigint, in_faction_id smallint, in_reputation_amount integer) -> void
-- oid: 58594  kind: FUNCTION  category: faction

CREATE OR REPLACE FUNCTION dune.set_player_faction_reputation(in_actor_id bigint, in_faction_id smallint, in_reputation_amount integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	INSERT INTO player_faction_reputation (actor_id, faction_id, reputation_amount)
	VALUES (in_actor_id, in_faction_id, in_reputation_amount)
	ON CONFLICT (actor_id, faction_id)
		DO UPDATE
		SET reputation_amount = EXCLUDED.reputation_amount;
END
$function$
