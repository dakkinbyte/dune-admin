-- record_unreadied_spice_fields(in_server_id text, in_spicefield_type_id integer, in_num_unreadied integer) -> void
-- oid: 58506  kind: FUNCTION  category: spice_field

CREATE OR REPLACE FUNCTION dune.record_unreadied_spice_fields(in_server_id text, in_spicefield_type_id integer, in_num_unreadied integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE spicefield_types
	SET current_globally_primed = current_globally_primed - in_num_unreadied
	WHERE spicefield_type_id = in_spicefield_type_id;

	UPDATE spicefield_server_availability
	SET inactive_fields_of_type = inactive_fields_of_type + in_num_unreadied
	WHERE server_id = in_server_id AND spicefield_type_id = in_spicefield_type_id;
END; $function$
