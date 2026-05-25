-- landsraad_update_task_faction_reveal_state(in_term_id bigint, in_task_board_index integer, faction_name text, reveal_state boolean) -> void
-- oid: 58436  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_update_task_faction_reveal_state(in_term_id bigint, in_task_board_index integer, faction_name text, reveal_state boolean)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	taskid BIGINT = NULL;
	factionid BIGINT = NULL;
BEGIN
	SELECT id FROM landsraad_tasks tasks WHERE tasks.board_index = in_task_board_index AND tasks.term_id = in_term_id INTO taskid;
	
	IF taskid IS NULL THEN 
		RAISE EXCEPTION 'Cannot update landsraad task reveal state, no task id for index % term %', in_task_board_index, in_term_id;
	END IF;
	
	SELECT id FROM factions WHERE factions.name = faction_name INTO factionid;
	
	IF factionid IS NULL OR faction_name = 'None' THEN 
		RAISE EXCEPTION 'Cannot update landsraad task reveal state, invalid faction (%)', faction_name;
	END IF;
	
	INSERT INTO landsraad_task_reveal_state (task_id, faction_id, revealed, timestamp) VALUES (taskid, factionid, reveal_state, now()) ON CONFLICT(task_id, faction_id) DO UPDATE
		SET revealed = reveal_state, timestamp = now();

	PERFORM pg_notify('landsraad_notify_channel', 'progress_updated#{"changed": true}');	
END $function$
