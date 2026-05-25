-- create_event_log_partition() -> trigger
-- oid: 58181  kind: FUNCTION  category: event_log

CREATE OR REPLACE FUNCTION dune.create_event_log_partition()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    CALL create_event_log_partition_table('event_log', NEW.partition_id);

    RETURN NEW;
END;
$function$
