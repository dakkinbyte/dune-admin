-- landsraad_load_guild_vote(in_term_id bigint, in_player_id bigint) -> TABLE(decree_name text, voting_influence real)
-- oid: 58422  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_load_guild_vote(in_term_id bigint, in_player_id bigint)
 RETURNS TABLE(decree_name text, voting_influence real)
 LANGUAGE plpgsql
AS $function$
DECLARE
	term_winning_faction_id SMALLINT = NULL;
	player_guild_id BIGINT = NULL;
	guild_faction_id SMALLINT = NULL;
BEGIN
	SELECT guilds.guild_id, guilds.guild_faction FROM guild_members JOIN guilds ON guild_members.guild_id = guilds.guild_id WHERE guild_members.player_id = in_player_id INTO player_guild_id, guild_faction_id;

	RETURN query (
		SELECT 
			CASE WHEN player_guild_id IS NOT NULL AND guild_faction_id IS NOT NULL THEN
				(SELECT COALESCE(decrees.decree_name, '') FROM landsraad_decree_votes AS votes LEFT JOIN landsraad_decrees AS decrees ON votes.decree_id = decrees.id WHERE votes.guild_id = player_guild_id)
			ELSE
				''
			END,
			CASE WHEN player_guild_id IS NOT NULL AND guild_faction_id IS NOT NULL THEN
				(SELECT landsraad_load_guild_contribution(in_term_id, player_guild_id, guild_faction_id))
			ELSE
				0
			END
	);
END $function$
