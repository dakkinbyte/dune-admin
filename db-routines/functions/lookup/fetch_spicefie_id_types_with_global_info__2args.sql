-- fetch_spicefie_id_types_with_global_info(in_map_name text, in_dimension_index integer) -> TABLE(spicefield_type_id integer, max_globally_active integer, max_globally_primed integer, current_globally_active integer, current_globally_primed integer, is_spawning_active boolean, field_type text)
-- oid: 58262  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.fetch_spicefie_id_types_with_global_info(in_map_name text, in_dimension_index integer)
 RETURNS TABLE(spicefield_type_id integer, max_globally_active integer, max_globally_primed integer, current_globally_active integer, current_globally_primed integer, is_spawning_active boolean, field_type text)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT t.spicefield_type_id, t.max_globally_active, t.max_globally_primed, t.current_globally_active, t.current_globally_primed, t.is_spawning_active, t.field_type
    FROM spicefield_types as t
    WHERE t.map_name = in_map_name AND t.dimension_index = in_dimension_index;
END; $function$
