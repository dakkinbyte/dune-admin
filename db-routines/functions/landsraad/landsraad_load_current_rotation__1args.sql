-- landsraad_load_current_rotation(in_term_id bigint) -> TABLE(decree_name text, received_votes integer, open_votes integer)
-- oid: 58418  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_load_current_rotation(in_term_id bigint)
 RETURNS TABLE(decree_name text, received_votes integer, open_votes integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
	open_votes INTEGER = 0;
BEGIN
	WITH open_guild_votes AS (
		SELECT guild_contribution.guild_id, FLOOR(SUM(guild_contribution.amount))::INTEGER AS voting_influence
			FROM landsraad_tasks AS tasks 
			INNER JOIN landsraad_task_guild_contributions AS guild_contribution
			ON guild_contribution.task_id = tasks.id AND guild_contribution.faction_id = tasks.winning_faction_id
			LEFT JOIN landsraad_decree_votes 
			ON guild_contribution.guild_id = landsraad_decree_votes.guild_id 
			WHERE tasks.term_id = in_term_id AND tasks.winning_faction_id = (SELECT winning_faction_id FROM landsraad_decree_term WHERE term_id = in_term_id)
			AND landsraad_decree_votes.guild_id IS NULL
			GROUP BY (guild_contribution.guild_id, guild_contribution.faction_id)
	) 
	SELECT SUM(voting_influence)::INTEGER FROM open_guild_votes INTO open_votes;

	RETURN query (
		SELECT decrees.decree_name, SUM(decree_votes.influence)::INTEGER AS received_votes, open_votes
			FROM landsraad_decree_rotation AS rotation
			INNER JOIN landsraad_decrees AS decrees ON rotation.decree_id = decrees.id
			LEFT JOIN landsraad_decree_votes AS decree_votes ON decree_votes.decree_id = rotation.decree_id
			GROUP BY rotation.decree_id, decrees.decree_name
	);
END $function$
