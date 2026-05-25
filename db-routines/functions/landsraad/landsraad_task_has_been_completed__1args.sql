-- landsraad_task_has_been_completed(in_task_id bigint) -> boolean
-- oid: 58433  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_task_has_been_completed(in_task_id bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
    task_completed BOOLEAN = FALSE;
BEGIN
    SELECT task.completed FROM landsraad_tasks AS task WHERE task.id = in_task_id INTO task_completed;
    RETURN task_completed;
END $function$
