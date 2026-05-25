-- landsraad_collect_task_telemetry_for_faction(in_term_id bigint, in_faction_name text) -> TABLE(task_telemetry dune.landsraadtermtasktelemetry[])
-- oid: 58403  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_collect_task_telemetry_for_faction(in_term_id bigint, in_faction_name text)
 RETURNS TABLE(task_telemetry dune.landsraadtermtasktelemetry[])
 LANGUAGE plpgsql
AS $function$
DECLARE
	current_faction_id SMALLINT = NULL;
BEGIN
	SELECT id FROM factions WHERE factions.name = in_faction_name INTO current_faction_id;

	RETURN query SELECT ARRAY_AGG((in_faction_name, landsraad_tasks.house_name, task_reveal.revealed, (CASE WHEN winning_faction_id = current_faction_id THEN TRUE ELSE FALSE END), task_progress.participant_count, CAST(landsraad_tasks.board_index AS INTEGER), landsraad_tasks.completion_time)::LandsraadTermTaskTelemetry)
		FROM landsraad_tasks 
		LEFT JOIN landsraad_task_reveal_state task_reveal
            ON task_reveal.task_id = landsraad_tasks.id AND task_reveal.faction_id = current_faction_id
		LEFT JOIN LATERAL (
	        SELECT COUNT(DISTINCT ltpc.player_id) AS participant_count FROM landsraad_task_player_contributions ltpc WHERE ltpc.task_id = landsraad_tasks.id and ltpc.faction_id = current_faction_id GROUP BY task_id
        ) AS task_progress ON true
		WHERE landsraad_tasks.term_id = in_term_id;
END $function$
