-- landsraad_load_guild_contribution(in_term_id bigint, in_guild_id bigint, in_faction_id bigint) -> TABLE(voting_influence real)
-- oid: 58420  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_load_guild_contribution(in_term_id bigint, in_guild_id bigint, in_faction_id bigint)
 RETURNS TABLE(voting_influence real)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN query (
		SELECT SUM(guild_contribution.amount)::REAL
			FROM landsraad_tasks AS tasks 
			INNER JOIN landsraad_task_guild_contributions AS guild_contribution
			ON guild_contribution.task_id = tasks.id
			WHERE tasks.term_id = in_term_id AND guild_contribution.guild_id = in_guild_id AND guild_contribution.faction_id = in_faction_id
			GROUP BY (guild_contribution.guild_id, guild_contribution.faction_id)
	);
END $function$
