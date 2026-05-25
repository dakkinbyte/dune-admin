-- landsraad_load_current_term() -> TABLE(term_id bigint, reigning_faction_name text, active_decree_name text, winning_faction_name text, elected_decree_name text, start_time timestamp without time zone, end_time timestamp without time zone, tasks dune.landsraadtask[], term_task_rewards dune.landsraadtaskreward[], winner_history text[], testterm boolean)
-- oid: 58419  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_load_current_term()
 RETURNS TABLE(term_id bigint, reigning_faction_name text, active_decree_name text, winning_faction_name text, elected_decree_name text, start_time timestamp without time zone, end_time timestamp without time zone, tasks dune.landsraadtask[], term_task_rewards dune.landsraadtaskreward[], winner_history text[], testterm boolean)
 LANGUAGE plpgsql
AS $function$
DECLARE
	current_term_id BIGINT = NULL;
	reigning_faction_name TEXT = NULL;
	active_decree_name TEXT = NULL;
	winning_faction_name TEXT = NULL;
	elected_decree_name TEXT = NULL;
	start_time TIMESTAMP = NULL;
	end_time TIMESTAMP = NULL;
	test_term BOOL = NULL;
	term_tasks LandsraadTask[];
	term_task_rewards LandsraadTaskReward[];
	term_winner_history TEXT[];
BEGIN
	SELECT term.term_id, reigning_faction.name, active_decree.decree_name, winning_faction.name, elected_decree.decree_name, (term.start_time AT TIME ZONE 'UTC')::TIMESTAMP, (term.end_time AT TIME ZONE 'UTC')::TIMESTAMP, term.test_term
		INTO current_term_id, reigning_faction_name, active_decree_name, winning_faction_name, elected_decree_name, start_time, end_time, test_term
		FROM landsraad_decree_term AS term
		LEFT JOIN factions AS reigning_faction ON term.reigning_faction_id = reigning_faction.id 
		LEFT JOIN landsraad_decrees AS active_decree ON term.active_decree_id = active_decree.id
		LEFT JOIN factions AS winning_faction ON term.winning_faction_id = winning_faction.id
		LEFT JOIN landsraad_decrees AS elected_decree ON term.elected_decree_id = elected_decree.id
		ORDER BY term.start_time DESC LIMIT 1;

	SELECT ARRAY_AGG((tasks.board_index, tasks.house_name, tasks.completed, COALESCE(factions_winner.name, ''), tasks.sysselraad, tasks.goal_amount)::LandsraadTask)
        INTO term_tasks		
        FROM landsraad_tasks AS tasks 
		LEFT JOIN factions AS factions_winner ON tasks.winning_faction_id = factions_winner.id
		WHERE tasks.term_id = current_term_id;

	WITH task_rewards AS (
		SELECT tasks.house_name AS house_name, rewards.threshold AS threshold, rewards.template_id AS template_id, rewards.amount AS amount 
		FROM landsraad_task_rewards AS rewards
		LEFT JOIN landsraad_tasks AS tasks ON rewards.task_id = tasks.id
		WHERE tasks.term_id = current_term_id ORDER BY rewards.task_id ASC, rewards.threshold ASC
	)
	SELECT ARRAY_AGG((house_name, threshold, template_id, amount)::LandsraadTaskReward) FROM task_rewards INTO term_task_rewards;

	SELECT ARRAY_AGG(winning_factions.name::TEXT)
	INTO term_winner_history
	FROM
		(SELECT factions.name
			FROM landsraad_decree_term
			LEFT JOIN factions ON landsraad_decree_term.reigning_faction_id = factions.id
			ORDER BY landsraad_decree_term.term_id DESC) AS winning_factions;

	IF current_term_id IS NOT NULL THEN
		RETURN query SELECT current_term_id, reigning_faction_name, active_decree_name, winning_faction_name, elected_decree_name, start_time, end_time, term_tasks, term_task_rewards, term_winner_history, test_term;
	END IF;
END $function$
