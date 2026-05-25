-- remove_resourcefield_states(in_map text, in_dimension_index integer, in_field_ids bigint[]) -> void
-- oid: 58526  kind: FUNCTION  category: items_purge

CREATE OR REPLACE FUNCTION dune.remove_resourcefield_states(in_map text, in_dimension_index integer, in_field_ids bigint[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE 
	FROM resourcefield_state 
	WHERE field_id = ANY(in_field_ids) AND map = in_map AND dimension_index = in_dimension_index;
END
$function$
