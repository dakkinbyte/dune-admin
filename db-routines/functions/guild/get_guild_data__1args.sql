-- get_guild_data(in_guild_id bigint) -> TABLE(guild_name text, guild_faction_id smallint, guild_description text)
-- oid: 58307  kind: FUNCTION  category: guild

CREATE OR REPLACE FUNCTION dune.get_guild_data(in_guild_id bigint)
 RETURNS TABLE(guild_name text, guild_faction_id smallint, guild_description text)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY
	SELECT guilds.guild_name, guilds.guild_faction, guilds.guild_description
	FROM guilds
	WHERE guild_id = in_guild_id;
END
$function$
