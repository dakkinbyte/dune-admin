-- load_static_encounter_name(in_map_name text, in_package_name text, in_actor_name text) -> TABLE(encounter_name text, waiting_for_reset boolean)
-- oid: 58462  kind: FUNCTION  category: misc

CREATE OR REPLACE FUNCTION dune.load_static_encounter_name(in_map_name text, in_package_name text, in_actor_name text)
 RETURNS TABLE(encounter_name text, waiting_for_reset boolean)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY 
    SELECT t.encounter_name, t.waiting_for_reset
    FROM encounters_static as t
    WHERE t.map_name = in_map_name AND t.package_name = in_package_name AND t.actor_name = in_actor_name;
END; $function$
