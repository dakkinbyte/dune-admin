-- update_spice_field_spawn_state(in_is_spawning_active boolean, in_spicefield_type_id integer) -> void
-- oid: 58639  kind: FUNCTION  category: spice_field

CREATE OR REPLACE FUNCTION dune.update_spice_field_spawn_state(in_is_spawning_active boolean, in_spicefield_type_id integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE spicefield_types SET is_spawning_active = in_is_spawning_active WHERE spicefield_type_id = in_spicefield_type_id;
    UPDATE spicefield_server_availability SET requested_spawned_of_type = 0 WHERE spicefield_type_id = in_spicefield_type_id;
END; $function$
