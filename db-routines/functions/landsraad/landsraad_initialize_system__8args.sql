-- landsraad_initialize_system(number_of_weeks_term_retention integer, number_of_nominated_decrees integer, in_end_time timestamp without time zone, in_test_term boolean, faction_names text[], decrees dune.landsraaddecree[], tasks dune.landsraadtask[], task_rewards dune.landsraadtaskreward[]) -> TABLE(term_id bigint, reigning_faction_name text, active_decree_name text, winning_faction_name text, elected_decree_name text, start_time timestamp without time zone, end_time timestamp without time zone)
-- oid: 58411  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_initialize_system(number_of_weeks_term_retention integer, number_of_nominated_decrees integer, in_end_time timestamp without time zone, in_test_term boolean, faction_names text[], decrees dune.landsraaddecree[], tasks dune.landsraadtask[], task_rewards dune.landsraadtaskreward[])
 RETURNS TABLE(term_id bigint, reigning_faction_name text, active_decree_name text, winning_faction_name text, elected_decree_name text, start_time timestamp without time zone, end_time timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
DECLARE
	current_term_id BIGINT = NULL;
BEGIN
	LOCK TABLE landsraad_decree_term, landsraad_decree_rotation, landsraad_decrees, landsraad_decree_votes IN EXCLUSIVE MODE;

	CALL landsraad_update_decrees(decrees);
	
	CALL landsraad_update_factions(faction_names);

	SELECT term.term_id FROM landsraad_decree_term term ORDER BY term.term_id DESC LIMIT 1 INTO current_term_id;
	IF FOUND THEN
		RETURN query SELECT term.term_id, reigning_faction.name, active_decree.decree_name, winning_faction.name, elected_decree.decree_name, (term.start_time AT TIME ZONE 'UTC')::TIMESTAMP, (term.end_time AT TIME ZONE 'UTC')::TIMESTAMP
			FROM landsraad_decree_term term 
			LEFT JOIN factions reigning_faction ON term.reigning_faction_id = reigning_faction.id 
			LEFT JOIN landsraad_decrees active_decree ON term.active_decree_id = active_decree.id
			LEFT JOIN factions winning_faction ON term.winning_faction_id = winning_faction.id
			LEFT JOIN landsraad_decrees elected_decree ON term.elected_decree_id = elected_decree.id
			WHERE term.term_id = current_term_id;
	ELSE 
		RETURN query SELECT term.term_id, term.reigning_faction_name, term.active_decree_name, term.winning_faction_name, term.elected_decree_name, term.start_time, term.end_time
			FROM landsraad_initialize_term(number_of_weeks_term_retention, number_of_nominated_decrees, in_end_time, in_test_term, tasks, task_rewards) AS term;	
	END IF;
END $function$
