-- save_static_encounter_name(in_map_name text, in_package_name text, in_actor_name text, in_encounter_name text) -> void
-- oid: 58564  kind: FUNCTION  category: misc

CREATE OR REPLACE FUNCTION dune.save_static_encounter_name(in_map_name text, in_package_name text, in_actor_name text, in_encounter_name text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO encounters_static(map_name, package_name, actor_name, encounter_name, waiting_for_reset) 
    VALUES(in_map_name, in_package_name, in_actor_name, in_encounter_name, false) 
    ON CONFLICT(map_name, package_name, actor_name) 
    DO UPDATE SET encounter_name = in_encounter_name, waiting_for_reset = false 
    WHERE encounters_static.map_name = in_map_name AND encounters_static.package_name = in_package_name AND encounters_static.actor_name = in_actor_name;
END; $function$
