-- get_friends_search(in_player_name text, in_max_players_count integer) -> TABLE(player_id bigint, character_name text, funcom_id text, platform_id text, platform_name text)
-- oid: 58306  kind: FUNCTION  category: misc

CREATE OR REPLACE FUNCTION dune.get_friends_search(in_player_name text, in_max_players_count integer)
 RETURNS TABLE(player_id bigint, character_name text, funcom_id text, platform_id text, platform_name text)
 LANGUAGE plpgsql
AS $function$
BEGIN
		RETURN QUERY SELECT player_state.player_controller_id, player_state.character_name, accounts.funcom_id, accounts.platform_id, accounts.platform_name
		FROM player_state
		JOIN accounts ON player_state.account_id = accounts.id
		WHERE player_state.character_name ILIKE '%' || in_player_name || '%'
		ORDER BY ext.SIMILARITY(player_state.character_name, in_player_name) DESC
		LIMIT in_max_players_count;
END
$function$
