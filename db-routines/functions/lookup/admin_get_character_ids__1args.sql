-- admin_get_character_ids(in_search_term text) -> TABLE(id bigint, "user" text, character_name text)
-- oid: 58131  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.admin_get_character_ids(in_search_term text)
 RETURNS TABLE(id bigint, "user" text, character_name text)
 LANGUAGE plpgsql
AS $function$
begin
	return query
	select accounts.id, accounts.user, player_state.character_name
	from accounts
	left join player_state on player_state.account_id = accounts.id
	where lower(accounts.user) like in_search_term or lower(player_state.character_name) like in_search_term;
end
$function$
