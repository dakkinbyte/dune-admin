-- landsraad_check_term_won() -> trigger
-- oid: 58402  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_check_term_won()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	row_completed BIGINT[] = NULL;
	column_completed BIGINT[] = NULL;
	diagonal_1_completed BIGINT[] = NULL; 
	diagonal_2_completed BIGINT[] = NULL;
	sysselraad_amount INTEGER = 0;
BEGIN
	-- check for sysselrad rule (a row, a column or a diagonal completed by a faction)
	WITH board AS (SELECT task.id as task_id, task.winning_faction_id, task.board_index / 5 AS row, task.board_index % 5 AS col, task.sysselraad FROM landsraad_tasks task WHERE task.term_id = NEW.term_id)
	SELECT 
		(SELECT array_agg(board.task_id) FROM board WHERE board.row = ANY(SELECT board.row FROM board WHERE board.winning_faction_id = NEW.winning_faction_id GROUP BY (board.row) HAVING COUNT(board.col) = 5)),
		(SELECT array_agg(board.task_id) FROM board WHERE board.col = ANY(SELECT board.col FROM board WHERE board.winning_faction_id = NEW.winning_faction_id GROUP BY (board.col) HAVING COUNT(board.row) = 5)),
		(SELECT CASE WHEN COUNT(board.winning_faction_id) = 5 THEN array_agg(board.task_id) END FROM ( VALUES (0, 0), (1, 1), (2, 2), (3, 3), (4, 4) ) AS t(row, col) JOIN board ON board.row = t.row AND board.col = t.col WHERE board.winning_faction_id = NEW.winning_faction_id),
		(SELECT CASE WHEN COUNT(board.winning_faction_id) = 5 THEN array_agg(board.task_id) END FROM ( VALUES (0, 4), (1, 3), (2, 2), (3, 1), (4, 0) ) AS t(row, col) JOIN board ON board.row = t.row AND board.col = t.col WHERE board.winning_faction_id = NEW.winning_faction_id),
		(SELECT COUNT(*) FROM board WHERE board.sysselraad)
	INTO row_completed, column_completed, diagonal_1_completed, diagonal_2_completed, sysselraad_amount;

	IF sysselraad_amount = 0 AND (row_completed IS NOT NULL OR column_completed IS NOT NULL OR diagonal_1_completed IS NOT NULL OR diagonal_2_completed IS NOT NULL) THEN
		UPDATE landsraad_tasks SET sysselraad = TRUE WHERE id = ANY(row_completed || column_completed || diagonal_1_completed || diagonal_2_completed);
		UPDATE landsraad_decree_term SET winning_faction_id = NEW.winning_faction_id WHERE term_id = NEW.term_id AND winning_faction_id IS NULL;
		PERFORM pg_notify('landsraad_notify_channel', 'state_changed');
	END IF;

	RETURN NULL;
END $function$
