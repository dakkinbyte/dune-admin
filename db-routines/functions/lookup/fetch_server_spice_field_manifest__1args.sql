-- fetch_server_spice_field_manifest(in_server_id text) -> TABLE(spicefield_type_id integer, inactive_fields_of_type integer, requested_spawned_of_type integer)
-- oid: 58261  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.fetch_server_spice_field_manifest(in_server_id text)
 RETURNS TABLE(spicefield_type_id integer, inactive_fields_of_type integer, requested_spawned_of_type integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT t.spicefield_type_id, t.inactive_fields_of_type, t.requested_spawned_of_type
    FROM spicefield_server_availability as t
    WHERE t.server_id = in_server_id;
END; $function$
