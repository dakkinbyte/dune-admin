-- register_spice_field_server_resources(in_server_id text, in_spicefield_type_ids integer[], in_inactive_fields_of_types integer[]) -> void
-- oid: 58512  kind: FUNCTION  category: spice_field

CREATE OR REPLACE FUNCTION dune.register_spice_field_server_resources(in_server_id text, in_spicefield_type_ids integer[], in_inactive_fields_of_types integer[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO spicefield_server_availability(server_id, spicefield_type_id, inactive_fields_of_type)
	SELECT in_server_id, unnest(in_spicefield_type_ids), unnest(in_inactive_fields_of_types)
	ON CONFLICT(server_id, spicefield_type_id)
	DO UPDATE SET server_id = excluded.server_id, spicefield_type_id = excluded.spicefield_type_id, inactive_fields_of_type = excluded.inactive_fields_of_type;
END; $function$
