-- get_players_demo_data(in_controller_ids bigint[]) -> SETOF dune.playerdemostatedescription
-- oid: 58346  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_players_demo_data(in_controller_ids bigint[])
 RETURNS SETOF dune.playerdemostatedescription
 LANGUAGE plpgsql
AS $function$
BEGIN
 	RETURN QUERY SELECT ps.player_controller_id, (ps.last_avatar_activity AT TIME ZONE 'UTC')::TIMESTAMP, demo_playtime_seconds, demo_state
	FROM encrypted_accounts acc
	JOIN player_state ps ON ps.account_id = acc.id
	JOIN demo_users du ON acc.user = du.fls_id
    WHERE ps.player_controller_id = ANY (in_controller_ids);
END
$function$
