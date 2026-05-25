-- landsraad_process_house_rewards() -> trigger
-- oid: 58431  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_process_house_rewards()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
	WITH 
		task_player_contribution_threshold_passed (player_id, house_name, template_id, amount) AS (
			SELECT NEW.player_id, tasks.house_name, task_rewards.template_id, task_rewards.amount
			FROM landsraad_task_rewards as task_rewards
            INNER JOIN landsraad_tasks AS tasks
            ON task_rewards.task_id = tasks.id
			LEFT JOIN landsraad_task_player_contributions AS player_contributions
			ON player_contributions.task_id = tasks.id
			WHERE task_rewards.task_id = NEW.task_id
				AND tasks.id = NEW.task_id 
				AND player_contributions.player_id = NEW.player_id
                AND COALESCE(OLD.amount, 0) < task_rewards.threshold
				AND NEW.amount >= task_rewards.threshold)
	INSERT INTO landsraad_house_rewards (player_id, house_name, template_id, amount, last_updated)
		SELECT player_id, house_name, template_id, SUM(amount), CURRENT_TIMESTAMP FROM task_player_contribution_threshold_passed GROUP BY player_id, house_name, template_id
		ON CONFLICT (player_id, house_name, template_id) DO UPDATE SET amount = landsraad_house_rewards.amount + excluded.amount, last_updated = CURRENT_TIMESTAMP;

	RETURN NULL;
END $function$
