-- delete_static_location_markers(p_location_keys text[]) -> void
-- oid: 58231  kind: FUNCTION  category: markers

CREATE OR REPLACE FUNCTION dune.delete_static_location_markers(p_location_keys text[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    DELETE FROM markers WHERE (payload #>> '{LocationKey}') = ANY(p_location_keys);
END;
$function$
