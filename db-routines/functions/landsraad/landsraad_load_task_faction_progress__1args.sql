-- landsraad_load_task_faction_progress(in_term_id bigint) -> TABLE(task_board_index integer, faction_name text, progress integer)
-- oid: 58425  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_load_task_faction_progress(in_term_id bigint)
 RETURNS TABLE(task_board_index integer, faction_name text, progress integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN query SELECT CAST(faction_progress.board_index AS INTEGER), faction_progress.name, CAST(faction_progress.progress AS INTEGER) FROM 
		(SELECT tasks.id, tasks.board_index, factions.name, SUM(faction_contribution.amount) AS progress
			FROM landsraad_tasks tasks 
			INNER JOIN landsraad_task_faction_contributions faction_contribution
			ON faction_contribution.task_id = tasks.id
			LEFT JOIN factions factions
			ON factions.id = faction_contribution.faction_id
			WHERE tasks.term_id = in_term_id
			GROUP BY (tasks.id, tasks.board_index, factions.name)) AS faction_progress;
END $function$
