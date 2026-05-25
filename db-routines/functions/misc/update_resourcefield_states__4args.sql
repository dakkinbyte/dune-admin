-- update_resourcefield_states(in_map text, in_dimension_index integer, in_field_kind_id smallint, in_field_states dune.resourcefieldstateentry[]) -> void
-- oid: 58631  kind: FUNCTION  category: misc

CREATE OR REPLACE FUNCTION dune.update_resourcefield_states(in_map text, in_dimension_index integer, in_field_kind_id smallint, in_field_states dune.resourcefieldstateentry[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	INSERT INTO resourcefield_state(map, dimension_index, field_kind_id, field_id, spawn_time, value_remaining) 
	SELECT in_map, in_dimension_index, in_field_kind_id, * FROM UNNEST(in_field_states)
	ON CONFLICT("field_id", "map", "dimension_index") DO
	UPDATE
	SET value_remaining = EXCLUDED.value_remaining 
	WHERE resourcefield_state.field_id = EXCLUDED.field_id AND resourcefield_state.map = in_map AND resourcefield_state.dimension_index = in_dimension_index;
END
$function$
