-- get_all_guild_members() -> TABLE(player_id bigint, fls_id text, guild_id bigint)
-- oid: 58275  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_all_guild_members()
 RETURNS TABLE(player_id bigint, fls_id text, guild_id bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY
	SELECT gm.player_id, acc.user, gm.guild_id
	FROM accounts acc
	LEFT JOIN player_state ps ON acc.id = ps.account_id
	RIGHT JOIN guild_members gm ON ps.player_controller_id = gm.player_id;
END
$function$
