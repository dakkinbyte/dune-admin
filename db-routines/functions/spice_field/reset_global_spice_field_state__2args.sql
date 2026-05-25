-- reset_global_spice_field_state(in_map_name text, in_dimension_index integer) -> void
-- oid: 58529  kind: FUNCTION  category: spice_field

CREATE OR REPLACE FUNCTION dune.reset_global_spice_field_state(in_map_name text, in_dimension_index integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE spicefield_server_availability sa
	SET requested_spawned_of_type = 0
	FROM spicefield_types st
	WHERE sa.spicefield_type_id = st.spicefield_type_id AND st.map_name = in_map_name AND st.dimension_index = in_dimension_index;

	UPDATE spicefield_types
	SET current_globally_primed = 0, current_globally_active = 0
	WHERE map_name = in_map_name AND dimension_index = in_dimension_index;
END; $function$
