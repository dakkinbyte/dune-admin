-- get_all_player_character_home_dimensions() -> TABLE(fls_id text, home_dimension integer)
-- oid: 58280  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_all_player_character_home_dimensions()
 RETURNS TABLE(fls_id text, home_dimension integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY SELECT accounts.user as fls_id, player_state.home_dimension_index as home_dimension
	FROM accounts
	LEFT JOIN player_state on player_state.account_id = accounts.id;
END
$function$
