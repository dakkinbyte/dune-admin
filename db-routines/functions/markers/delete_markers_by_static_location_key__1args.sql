-- delete_markers_by_static_location_key(p_location_key text) -> void
-- oid: 58224  kind: FUNCTION  category: markers

CREATE OR REPLACE FUNCTION dune.delete_markers_by_static_location_key(p_location_key text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    DELETE FROM markers WHERE (payload #>> '{LocationKey}') = p_location_key;
END;
$function$
