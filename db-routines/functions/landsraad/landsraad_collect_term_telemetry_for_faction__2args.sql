-- landsraad_collect_term_telemetry_for_faction(in_term_id bigint, in_faction_name text) -> dune.landsraadtermtelemetry
-- oid: 58405  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_collect_term_telemetry_for_faction(in_term_id bigint, in_faction_name text)
 RETURNS dune.landsraadtermtelemetry
 LANGUAGE plpgsql
AS $function$
DECLARE
	current_faction_id SMALLINT = NULL;
	winning_faction_id SMALLINT = NULL;
	start_time TIMESTAMPTZ = NULL;
	end_time TIMESTAMPTZ = NULL;
	sysselraad_count INTEGER = NULL;
	term_result TEXT = NULL;
	faction_won BOOLEAN = FALSE;
	participants_num_faction INTEGER = NULL;
	tasks_completed INTEGER = NULL;
	tasks_revealed INTEGER = NULL;
BEGIN
	SELECT id FROM factions WHERE factions.name = in_faction_name INTO current_faction_id;

	SELECT term.winning_faction_id, term.start_time, term.end_time FROM landsraad_decree_term AS term WHERE term_id = in_term_id INTO winning_faction_id, start_time, end_time;
	
	IF winning_faction_id IS NULL THEN
		term_result = 'TIE';
	ELSE
		SELECT COUNT(id) FROM landsraad_tasks WHERE term_id = in_term_id AND sysselraad = true INTO sysselraad_count;
		IF sysselraad_count = 5 THEN
			term_result = 'SYSSELRAAD';
		ELSE
			term_result = 'TASK_COUNT';
		END IF;
	END IF;

	IF winning_faction_id = current_faction_id THEN
		faction_won = true;
	END IF;
	
	SELECT COUNT(DISTINCT player_id) FROM landsraad_task_player_contributions LEFT JOIN landsraad_tasks ON
		landsraad_task_player_contributions.task_id = landsraad_tasks.id 
		WHERE landsraad_tasks.term_id = in_term_id AND landsraad_task_player_contributions.faction_id = current_faction_id
		INTO participants_num_faction;
	
	SELECT COUNT(id) FROM landsraad_tasks WHERE landsraad_tasks.term_id = in_term_id
		AND landsraad_tasks.winning_faction_id = current_faction_id AND landsraad_tasks.completed = true
		INTO tasks_completed;
		
	SELECT COUNT(DISTINCT landsraad_tasks.id) FROM landsraad_task_reveal_state LEFT JOIN landsraad_tasks ON
		landsraad_task_reveal_state.task_id = landsraad_tasks.id
		WHERE landsraad_tasks.term_id = in_term_id AND landsraad_task_reveal_state.faction_id = current_faction_id AND landsraad_task_reveal_state.revealed = true
		INTO tasks_revealed;
		
	RETURN (in_faction_name, term_result, faction_won, participants_num_faction, tasks_completed, tasks_revealed, start_time, end_time)::LandsraadTermTelemetry;
END $function$
