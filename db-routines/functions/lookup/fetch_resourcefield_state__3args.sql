-- fetch_resourcefield_state(in_map text, in_dimension_index integer, in_field_kind_id smallint) -> TABLE(field_id bigint, spawn_time double precision, value_remaining bigint)
-- oid: 58260  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.fetch_resourcefield_state(in_map text, in_dimension_index integer, in_field_kind_id smallint)
 RETURNS TABLE(field_id bigint, spawn_time double precision, value_remaining bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY 
	SELECT resourcefield_state.field_id, resourcefield_state.spawn_time, resourcefield_state.value_remaining 
	FROM resourcefield_state 
	WHERE map = in_map AND dimension_index = in_dimension_index AND field_kind_id = in_field_kind_id;
END
$function$
