-- landsraad_load_guild_contributions(in_term_id bigint, in_num_guilds integer, in_faction_names text[]) -> TABLE(faction_name text, guild_name text, voting_influence real)
-- oid: 58421  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_load_guild_contributions(in_term_id bigint, in_num_guilds integer, in_faction_names text[])
 RETURNS TABLE(faction_name text, guild_name text, voting_influence real)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN query (
		SELECT factions.name, top_guilds.guild_name, top_guilds.influence FROM factions
		CROSS JOIN LATERAL (
			SELECT guilds.guild_name as guild_name, SUM(guild_contribution.amount)::REAL AS influence
			FROM landsraad_tasks AS tasks 
			INNER JOIN landsraad_task_guild_contributions AS guild_contribution
			ON guild_contribution.task_id = tasks.id AND guild_contribution.faction_id = factions.id
			JOIN guilds
			ON guild_contribution.guild_id = guilds.guild_id
			WHERE tasks.term_id = in_term_id
			GROUP BY (guilds.guild_id, guilds.guild_name)
			ORDER BY influence DESC LIMIT in_num_guilds
		) AS top_guilds
		WHERE factions.name = ANY(in_faction_names)	
	);
END $function$
