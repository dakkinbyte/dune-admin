-- landsraad_has_term_of_task_ended(in_task_id bigint) -> boolean
-- oid: 58410  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_has_term_of_task_ended(in_task_id bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	term_ended BOOLEAN = FALSE;
BEGIN
    SELECT NOW() > term.end_time FROM landsraad_tasks AS task LEFT JOIN landsraad_decree_term AS term ON task.term_id = term.term_id WHERE task.id = in_task_id INTO term_ended;
    RETURN term_ended;
END $function$
