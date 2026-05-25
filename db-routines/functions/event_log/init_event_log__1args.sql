-- init_event_log(in_partition_id bigint) -> void
-- oid: 58379  kind: FUNCTION  category: event_log

CREATE OR REPLACE FUNCTION dune.init_event_log(in_partition_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    threshold_ts TIMESTAMPTZ;
	last_ts TIMESTAMPTZ;
	cleanup_threshold_days CONSTANT INTEGER := 14;
BEGIN
	-- calculate threshold
	threshold_ts := now() - (cleanup_threshold_days * interval '1 day');

	-- lock table
	LOCK TABLE event_log_maintanence IN EXCLUSIVE MODE;

	SELECT last_cleanup
	INTO last_ts
	FROM event_log_maintanence;

	IF last_ts < threshold_ts THEN    
		-- delete events older then the passed in threshold
		DELETE FROM event_log
		WHERE event_time < threshold_ts;

		-- Update last_cleanup in event_log_maintanence
		UPDATE event_log_maintanence
		SET last_cleanup = now();
	END IF;

	-- update partition_id
	PERFORM set_config('dune.partition_id', in_partition_id::TEXT, false);
END;
$function$
