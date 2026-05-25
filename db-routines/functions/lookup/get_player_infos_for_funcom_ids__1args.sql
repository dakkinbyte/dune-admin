-- get_player_infos_for_funcom_ids(in_funcom_ids text[]) -> TABLE(player_id bigint, character_name text, fls_id text, funcom_id text, platform_id text, platform_name text)
-- oid: 58340  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_player_infos_for_funcom_ids(in_funcom_ids text[])
 RETURNS TABLE(player_id bigint, character_name text, fls_id text, funcom_id text, platform_id text, platform_name text)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY SELECT ps.player_controller_id, ps.character_name, acc.user, acc.funcom_id, acc.platform_id, acc.platform_name
	FROM accounts acc LEFT JOIN player_state ps ON acc.id=ps.account_id
	WHERE acc.funcom_id = ANY(in_funcom_ids);
END
$function$
