-- landsraad_collect_vote_telemetry(in_term_id bigint, in_winning_faction_id integer) -> TABLE(guild_id bigint, decree_name text, voting_influence integer)
-- oid: 58406  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_collect_vote_telemetry(in_term_id bigint, in_winning_faction_id integer)
 RETURNS TABLE(guild_id bigint, decree_name text, voting_influence integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN query SELECT guild_contribution.guild_id, landsraad_decrees.decree_name, FLOOR(SUM(guild_contribution.amount))::INTEGER
			FROM landsraad_tasks AS tasks 
			INNER JOIN landsraad_task_guild_contributions AS guild_contribution 
			ON guild_contribution.task_id = tasks.id AND guild_contribution.faction_id = tasks.winning_faction_id AND tasks.term_id = in_term_id AND guild_contribution.faction_id = in_winning_faction_id
			LEFT JOIN landsraad_decree_votes 
			ON landsraad_decree_votes.guild_id = guild_contribution.guild_id
			LEFT JOIN landsraad_decrees 
			ON landsraad_decree_votes.decree_id = landsraad_decrees.id
			GROUP BY (guild_contribution.guild_id, landsraad_decrees.decree_name);
END $function$
