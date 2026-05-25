-- wipe_old_events_log(in_days_limit integer) -> void
-- oid: 58650  kind: FUNCTION  category: cleanup

CREATE OR REPLACE FUNCTION dune.wipe_old_events_log(in_days_limit integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM game_events WHERE universe_time < to_timestamp(in_days_limit);
END
$function$
