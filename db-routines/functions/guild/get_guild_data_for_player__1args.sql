-- get_guild_data_for_player(in_player_id bigint) -> TABLE(guild_id bigint, guild_factions_id smallint, guild_name text, guild_description text, player_id bigint, role_id smallint, player_faction_id smallint)
-- oid: 58308  kind: FUNCTION  category: guild

CREATE OR REPLACE FUNCTION dune.get_guild_data_for_player(in_player_id bigint)
 RETURNS TABLE(guild_id bigint, guild_factions_id smallint, guild_name text, guild_description text, player_id bigint, role_id smallint, player_faction_id smallint)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY
	SELECT guilds.guild_id, guilds.guild_faction, guilds.guild_name, guilds.guild_description, guild_members.player_id, guild_members.role_id, player_faction.faction_id
	FROM guilds JOIN guild_members on (guilds.guild_id = guild_members.guild_id)
	LEFT JOIN player_faction on player_faction.actor_id = guild_members.player_id
	WHERE guild_members.player_id = in_player_id;
END
$function$
