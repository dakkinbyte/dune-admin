-- record_deactivated_spice_field(in_server_id text, in_spicefield_type_id integer) -> void
-- oid: 58502  kind: FUNCTION  category: spice_field

CREATE OR REPLACE FUNCTION dune.record_deactivated_spice_field(in_server_id text, in_spicefield_type_id integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE spicefield_server_availability
	SET inactive_fields_of_type = inactive_fields_of_type + 1
	WHERE server_id = in_server_id AND spicefield_type_id = in_spicefield_type_id;

	UPDATE spicefield_types
	SET current_globally_active = current_globally_active - 1
	WHERE spicefield_type_id = in_spicefield_type_id;
END; $function$
