-- landsraad_collect_term_telemetry(in_term_id bigint, in_faction_names text[]) -> TABLE(term_telemetry dune.landsraadtermtelemetry[], task_telemetry dune.landsraadtermtasktelemetry[])
-- oid: 58404  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_collect_term_telemetry(in_term_id bigint, in_faction_names text[])
 RETURNS TABLE(term_telemetry dune.landsraadtermtelemetry[], task_telemetry dune.landsraadtermtasktelemetry[])
 LANGUAGE plpgsql
AS $function$
DECLARE
	faction_name TEXT = NULL;
	term_telemetry LandsraadTermTelemetry[];
	task_telemetry LandsraadTermTaskTelemetry[];
BEGIN
	FOREACH faction_name IN ARRAY in_faction_names
	LOOP
		term_telemetry = ARRAY_APPEND(term_telemetry, landsraad_collect_term_telemetry_for_faction(in_term_id, faction_name));
		task_telemetry = ARRAY_CAT(task_telemetry, landsraad_collect_task_telemetry_for_faction(in_term_id, faction_name));
	END LOOP;
	
	RETURN query SELECT term_telemetry, task_telemetry;
END $function$
