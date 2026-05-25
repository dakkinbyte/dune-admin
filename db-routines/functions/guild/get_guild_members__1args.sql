-- get_guild_members(in_guild_id bigint) -> TABLE(player_id bigint, role_id smallint, player_faction_id smallint)
-- oid: 58311  kind: FUNCTION  category: guild

CREATE OR REPLACE FUNCTION dune.get_guild_members(in_guild_id bigint)
 RETURNS TABLE(player_id bigint, role_id smallint, player_faction_id smallint)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY
	SELECT guild_members.player_id, guild_members.role_id, player_faction.faction_id
	FROM guild_members
	LEFT JOIN player_faction ON player_faction.actor_id = guild_members.player_id
	WHERE guild_id = in_guild_id;
END
$function$
