-- landsraad_insert_task_progress_batched(in_term_id bigint, in_task_progress dune.landsraadtaskprogress[]) -> void
-- oid: 58414  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_insert_task_progress_batched(in_term_id bigint, in_task_progress dune.landsraadtaskprogress[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	task_progress record = NULL;
BEGIN
	FOREACH task_progress IN ARRAY in_task_progress
	LOOP
		PERFORM landsraad_insert_task_progress(in_term_id, task_progress.player_id, task_progress.guild_id ,task_progress.house_name, task_progress.faction_progress, task_progress.guild_progress, task_progress.player_progress, task_progress.timestamp);
	END LOOP;
END $function$
