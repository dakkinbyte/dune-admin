-- landsraad_insert_tasks(IN in_term_id bigint, IN in_tasks dune.landsraadtask[], IN in_task_rewards dune.landsraadtaskreward[]) -> void
-- oid: 58417  kind: PROCEDURE  category: landsraad

CREATE OR REPLACE PROCEDURE dune.landsraad_insert_tasks(IN in_term_id bigint, IN in_tasks dune.landsraadtask[], IN in_task_rewards dune.landsraadtaskreward[])
 LANGUAGE plpgsql
AS $procedure$
BEGIN
	INSERT INTO landsraad_tasks (term_id, board_index, house_name, goal_amount)
		SELECT in_term_id, tasks.board_index, tasks.house_name, tasks.goal_amount FROM UNNEST(in_tasks) AS tasks;
		
	INSERT INTO landsraad_task_rewards (task_id, threshold, template_id, amount)
		SELECT tasks.id, task_rewards.threshold, task_rewards.template_id, task_rewards.amount FROM UNNEST(in_task_rewards) AS task_rewards
		LEFT JOIN landsraad_tasks AS tasks ON task_rewards.house_name = tasks.house_name WHERE tasks.term_id = in_term_id;
END $procedure$
