-- landsraad_check_task_completion() -> trigger
-- oid: 58401  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_check_task_completion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	task_completed BOOLEAN = FALSE;
BEGIN
	-- if a faction reached the tasks's goal amount set the task as completed
	WITH faction_progress AS (SELECT landsraad_task_faction_contributions.task_id, SUM(landsraad_task_faction_contributions.amount) AS amount  FROM landsraad_task_faction_contributions 
	WHERE landsraad_task_faction_contributions.task_id = NEW.task_id AND faction_id = NEW.faction_id GROUP BY faction_id, landsraad_task_faction_contributions.task_id)
		SELECT COALESCE (faction_progress.amount, 0) >= landsraad_tasks.goal_amount 
		FROM landsraad_tasks LEFT JOIN faction_progress ON landsraad_tasks.id = faction_progress.task_id
		WHERE landsraad_tasks.id = NEW.task_id
		INTO task_completed;

	IF task_completed THEN
		UPDATE landsraad_tasks SET completed = TRUE, winning_faction_id = NEW.faction_id, completion_time = NOW() WHERE id = NEW.task_id AND completed = FALSE;
		PERFORM pg_notify('landsraad_notify_channel', 'state_changed');
	END IF;

	RETURN NULL;
END $function$
