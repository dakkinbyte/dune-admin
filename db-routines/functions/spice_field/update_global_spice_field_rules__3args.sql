-- update_global_spice_field_rules(in_max_globally_primed integer, in_max_globally_active integer, in_spicefield_type_id integer) -> void
-- oid: 58621  kind: FUNCTION  category: spice_field

CREATE OR REPLACE FUNCTION dune.update_global_spice_field_rules(in_max_globally_primed integer, in_max_globally_active integer, in_spicefield_type_id integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE spicefield_types SET max_globally_primed = in_max_globally_primed, max_globally_active = in_max_globally_active WHERE spicefield_type_id = in_spicefield_type_id;
END; $function$
