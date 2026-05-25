-- landsraad_perform_daily_task_reveal(in_term_id bigint, in_faction_names text[], in_house_names_to_reveal text[], in_reveal_day integer) -> TABLE(faction_name text, house_name text, board_index integer)
-- oid: 58430  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_perform_daily_task_reveal(in_term_id bigint, in_faction_names text[], in_house_names_to_reveal text[], in_reveal_day integer)
 RETURNS TABLE(faction_name text, house_name text, board_index integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    last_processed_reveal_day INTEGER = NULL;
    faction_ids BIGINT[];
	newly_revealed_task_ids BIGINT[];
	newly_revealed_house_names TEXT[];
	newly_revealed_task_board_indices INTEGER[];
    faction_of_newly_revealed_task BIGINT[];
BEGIN
    LOCK TABLE landsraad_decree_term IN EXCLUSIVE MODE;
    
    SELECT landsraad_decree_term.last_processed_reveal_day FROM landsraad_decree_term WHERE term_id = in_term_id INTO last_processed_reveal_day;

    IF last_processed_reveal_day < in_reveal_day THEN
        SELECT ARRAY_AGG(factions.id) FROM factions WHERE factions.name = ANY(in_faction_names) INTO faction_ids;
                
        WITH revealed_task(id, faction_id) AS (
            SELECT task.id, faction.id FROM landsraad_tasks AS task
                CROSS JOIN UNNEST(faction_ids) AS faction(id)
                WHERE task.house_name = ANY (in_house_names_to_reveal) AND task.term_id = in_term_id)
        --filter out tasks already revealed from data to not stomp reveal date or send duplicate reveal event in telemetry
        SELECT ARRAY_AGG(task.id), ARRAY_AGG(task.house_name), ARRAY_AGG(task.board_index), ARRAY_AGG(revealed_task.faction_id) FROM revealed_task
            INNER JOIN landsraad_tasks AS task ON task.id = revealed_task.id
            LEFT JOIN landsraad_task_reveal_state AS reveal_state ON task.id = reveal_state.task_id AND revealed_task.faction_id = reveal_state.faction_id
            WHERE reveal_state.revealed IS NULL OR reveal_state.revealed IS FALSE
            INTO newly_revealed_task_ids, newly_revealed_house_names, newly_revealed_task_board_indices, faction_of_newly_revealed_task;
        
        INSERT INTO landsraad_task_reveal_state (task_id, faction_id, revealed, timestamp) SELECT UNNEST(newly_revealed_task_ids), UNNEST(faction_of_newly_revealed_task), TRUE, now() 
            ON CONFLICT(task_id, faction_id) DO UPDATE SET revealed = TRUE, timestamp = now();
        
        UPDATE landsraad_decree_term SET last_processed_reveal_day = in_reveal_day WHERE term_id = in_term_id;
        
        IF cardinality(newly_revealed_task_ids) > 0 THEN
            PERFORM pg_notify('landsraad_notify_channel', 'progress_updated#{"changed": true}');
        END IF;
    END IF;

	RETURN query
        WITH newly_revealed_tasks (house_name, board_index, faction_id) AS (
            SELECT UNNEST(newly_revealed_house_names), UNNEST(newly_revealed_task_board_indices), UNNEST(faction_of_newly_revealed_task))
        SELECT factions.name, newly_revealed_tasks.house_name, newly_revealed_tasks.board_index FROM newly_revealed_tasks JOIN factions ON newly_revealed_tasks.faction_id = factions.id;
END $function$
