-- add_event_log_data_batched(in_data dune.eventlogbulkentrydata[]) -> void
-- oid: 58120  kind: FUNCTION  category: event_log

CREATE OR REPLACE FUNCTION dune.add_event_log_data_batched(in_data dune.eventlogbulkentrydata[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	data_entry record = NULL;
BEGIN
	FOREACH data_entry IN ARRAY in_data
	LOOP
		PERFORM add_event_log_data(data_entry.game_event_owner, data_entry.universe_time, data_entry.map_name, data_entry.partition_id, data_entry.event_type,
			data_entry.x_location, data_entry.y_location, data_entry.z_location, data_entry.player_facing_event, data_entry.custom_args);
	END LOOP;
END $function$
