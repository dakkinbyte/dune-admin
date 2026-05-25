-- landsraad_load_task_faction_reveal_state(in_term_id bigint) -> TABLE(task_board_index integer, faction_name text, reveal_state boolean, time_stamp timestamp without time zone)
-- oid: 58426  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_load_task_faction_reveal_state(in_term_id bigint)
 RETURNS TABLE(task_board_index integer, faction_name text, reveal_state boolean, time_stamp timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN query SELECT CAST(tasks.board_index AS INTEGER), factions.name, reveal_state.revealed, (reveal_state.timestamp AT TIME ZONE 'UTC')::TIMESTAMP
			FROM landsraad_tasks tasks 
			INNER JOIN landsraad_task_reveal_state reveal_state
			ON reveal_state.task_id = tasks.id
			INNER JOIN factions factions
			ON factions.id = reveal_state.faction_id
			WHERE tasks.term_id = in_term_id;
END $function$
