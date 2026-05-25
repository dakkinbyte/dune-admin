-- load_takeoverable_user_ids() -> SETOF dune.takeovercharacterdatacomposite
-- oid: 58463  kind: FUNCTION  category: takeover

CREATE OR REPLACE FUNCTION dune.load_takeoverable_user_ids()
 RETURNS SETOF dune.takeovercharacterdatacomposite
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
	SELECT acc.user, ps.character_name
	FROM accounts acc LEFT JOIN player_state ps ON acc.id=ps.account_id
	WHERE acc.takeoverable=true;
END; $function$
