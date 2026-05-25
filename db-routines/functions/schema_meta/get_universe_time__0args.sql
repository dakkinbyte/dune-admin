-- get_universe_time() -> TABLE(universe_time_timestamp timestamp without time zone, down_time_accumulation bigint)
-- oid: 58362  kind: FUNCTION  category: schema_meta

CREATE OR REPLACE FUNCTION dune.get_universe_time()
 RETURNS TABLE(universe_time_timestamp timestamp without time zone, down_time_accumulation bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY SELECT farm_variables.universe_time_timestamp, farm_variables.down_time_accumulation from farm_variables;
	RETURN;
END
$function$
