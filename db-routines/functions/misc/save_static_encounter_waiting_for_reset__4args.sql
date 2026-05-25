-- save_static_encounter_waiting_for_reset(in_map_name text, in_package_name text, in_actor_name text, in_waiting_for_reset boolean) -> void
-- oid: 58565  kind: FUNCTION  category: misc

CREATE OR REPLACE FUNCTION dune.save_static_encounter_waiting_for_reset(in_map_name text, in_package_name text, in_actor_name text, in_waiting_for_reset boolean)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE encounters_static 
    SET waiting_for_reset = in_waiting_for_reset 
    WHERE encounters_static.map_name = in_map_name AND encounters_static.package_name = in_package_name AND encounters_static.actor_name = in_actor_name;
END; $function$
