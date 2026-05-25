-- update_universe_time(in_farm_id text) -> TABLE(universe_time_timestamp timestamp without time zone, down_time_accumulation bigint)
-- oid: 58642  kind: FUNCTION  category: schema_meta

CREATE OR REPLACE FUNCTION dune.update_universe_time(in_farm_id text DEFAULT NULL::text)
 RETURNS TABLE(universe_time_timestamp timestamp without time zone, down_time_accumulation bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE
BEGIN
	INSERT INTO farm_variables(farm_id, universe_time_timestamp, universe_lastactive_timestamp, down_time_accumulation, one_row)
	VALUES (in_farm_id, (CURRENT_TIMESTAMP AT TIME ZONE 'UTC')::TIMESTAMP, (CURRENT_TIMESTAMP AT TIME ZONE 'UTC')::TIMESTAMP, 0, true)
	ON CONFLICT(one_row) DO UPDATE
	SET
		down_time_accumulation = CASE
		WHEN farm_variables.farm_id != EXCLUDED.farm_id AND farm_variables.farm_id IS NOT NULL AND EXCLUDED.farm_id IS NOT NULL THEN farm_variables.down_time_accumulation + (EXTRACT(EPOCH FROM ((CURRENT_TIMESTAMP AT TIME ZONE 'UTC')::TIMESTAMP - farm_variables.universe_lastactive_timestamp)) * 1000000)::BIGINT
		ELSE farm_variables.down_time_accumulation
		END,
		universe_lastactive_timestamp = (CURRENT_TIMESTAMP AT TIME ZONE 'UTC')::TIMESTAMP,
		farm_id = CASE
		WHEN EXCLUDED.farm_id IS NULL AND farm_variables.farm_id IS NOT NULL THEN farm_variables.farm_id
		ELSE EXCLUDED.farm_id
		END;
	RETURN QUERY select * from get_universe_time();
	RETURN;
END
$function$
