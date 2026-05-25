-- create_event_log_partition_table(IN table_name text, IN partition_id bigint) -> void
-- oid: 58182  kind: PROCEDURE  category: event_log

CREATE OR REPLACE PROCEDURE dune.create_event_log_partition_table(IN table_name text, IN partition_id bigint)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
    start_range BIGINT;
    end_range BIGINT;
    partition_table_name TEXT;
BEGIN
    start_range := partition_id;
    end_range := partition_id + 1;
    partition_table_name := format('%s_p%s', table_name, partition_id);

    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I PARTITION OF %I
        FOR VALUES FROM (%s) TO (%s);
    ', partition_table_name, table_name, start_range, end_range);

END;
$procedure$
