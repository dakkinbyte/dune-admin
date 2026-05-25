-- upsert_spicefield_types(in_max_globally_active integer[], in_max_globally_primed integer[], in_field_types text[], in_map_name text, in_dimension_index integer) -> TABLE(type_id integer, max_global integer, max_global_primed integer, spawning_active boolean, out_field_type text)
-- oid: 58647  kind: FUNCTION  category: spice_field

CREATE OR REPLACE FUNCTION dune.upsert_spicefield_types(in_max_globally_active integer[], in_max_globally_primed integer[], in_field_types text[], in_map_name text, in_dimension_index integer)
 RETURNS TABLE(type_id integer, max_global integer, max_global_primed integer, spawning_active boolean, out_field_type text)
 LANGUAGE plpgsql
AS $function$
begin
	insert into spicefield_types (max_globally_active, max_globally_primed, field_type, map_name, dimension_index)
		select unnest(in_max_globally_active), unnest(in_max_globally_primed), unnest(in_field_types), in_map_name, in_dimension_index
		on conflict do nothing;
	return query select spicefield_type_id, max_globally_active, max_globally_primed, is_spawning_active, field_type::text from spicefield_types where map_name = in_map_name and dimension_index = in_dimension_index;
end $function$
