-- landsraad_initialize_term(number_of_weeks_term_retention integer, number_of_nominated_decrees integer, in_end_time timestamp without time zone, in_test_term boolean, tasks dune.landsraadtask[], task_rewards dune.landsraadtaskreward[]) -> TABLE(term_id bigint, reigning_faction_name text, active_decree_name text, winning_faction_name text, elected_decree_name text, start_time timestamp without time zone, end_time timestamp without time zone)
-- oid: 58412  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_initialize_term(number_of_weeks_term_retention integer, number_of_nominated_decrees integer, in_end_time timestamp without time zone, in_test_term boolean, tasks dune.landsraadtask[], task_rewards dune.landsraadtaskreward[])
 RETURNS TABLE(term_id bigint, reigning_faction_name text, active_decree_name text, winning_faction_name text, elected_decree_name text, start_time timestamp without time zone, end_time timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
DECLARE
	reigning_faction_id SMALLINT = NULL;
	active_decree_id BIGINT = NULL;
	last_active_decree_id BIGINT = NULL;
	current_term_id BIGINT = NULL;
BEGIN
	LOCK TABLE landsraad_decrees, landsraad_decree_term, landsraad_decree_rotation, landsraad_decree_votes IN EXCLUSIVE MODE;

	-- read winning faction, elected and active decree from previous term
	SELECT term.winning_faction_id, term.elected_decree_id, term.active_decree_id INTO reigning_faction_id, active_decree_id, last_active_decree_id FROM landsraad_decree_term term ORDER BY term.term_id DESC LIMIT 1;

	-- insert new term
	INSERT INTO landsraad_decree_term (reigning_faction_id, active_decree_id, start_time, end_time, test_term) VALUES(reigning_faction_id, active_decree_id, now(), in_end_time AT TIME ZONE 'UTC', in_test_term) RETURNING landsraad_decree_term.term_id INTO current_term_id;

	-- cleanup old terms, except for previous one
	DELETE FROM landsraad_decree_term term WHERE term.end_time < (now() - MAKE_INTERVAL(weeks => number_of_weeks_term_retention)) AND term.term_id < current_term_id - 1;

	-- insert tasks for new term
	CALL landsraad_insert_tasks(current_term_id, tasks, task_rewards);

	-- insert decrees for voting
	CALL landsraad_nominate_decrees_for_voting(last_active_decree_id, number_of_nominated_decrees);

	-- clean expired landsraad contracts
	PERFORM journey_story_node_cooldown_delete_expired(now() at time zone 'utc');

	RETURN query SELECT term.term_id, reigning_faction.name, active_decree.decree_name, winning_faction.name, elected_decree.decree_name, (term.start_time AT TIME ZONE 'UTC')::TIMESTAMP, (term.end_time AT TIME ZONE 'UTC')::TIMESTAMP
		FROM landsraad_decree_term term
		LEFT JOIN factions reigning_faction ON term.reigning_faction_id = reigning_faction.id 
		LEFT JOIN landsraad_decrees active_decree ON term.active_decree_id = active_decree.id
		LEFT JOIN factions winning_faction ON term.winning_faction_id = winning_faction.id
		LEFT JOIN landsraad_decrees elected_decree ON term.elected_decree_id = elected_decree.id
		WHERE term.term_id = current_term_id;
END $function$
