-- produce_spicefield_manifest(in_map_name text, in_dimension_index integer) -> TABLE(server text, type_id integer, inactive_fields integer, requested_fields integer)
-- oid: 58497  kind: FUNCTION  category: spice_field

CREATE OR REPLACE FUNCTION dune.produce_spicefield_manifest(in_map_name text, in_dimension_index integer)
 RETURNS TABLE(server text, type_id integer, inactive_fields integer, requested_fields integer)
 LANGUAGE plpgsql
AS $function$
begin
	return query
	select sa.server_id, sa.spicefield_type_id, sa.inactive_fields_of_type, sa.requested_spawned_of_type
	from spicefield_server_availability sa join spicefield_types st
	on sa.spicefield_type_id = st.spicefield_type_id
	where st.map_name = in_map_name and st.dimension_index = in_dimension_index
	order by server_id;
end $function$
