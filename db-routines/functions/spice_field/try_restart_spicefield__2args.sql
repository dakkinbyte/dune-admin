-- try_restart_spicefield(in_server_id text, in_spicefield_type_id integer) -> boolean
-- oid: 58611  kind: FUNCTION  category: spice_field

CREATE OR REPLACE FUNCTION dune.try_restart_spicefield(in_server_id text, in_spicefield_type_id integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
 BEGIN
	PERFORM spicefield_type_id
	FROM spicefield_types AS t
	WHERE t.spicefield_type_id = in_spicefield_type_id AND t.is_spawning_active IS TRUE;
	IF NOT FOUND THEN
		RETURN FALSE;
	END IF;

	UPDATE spicefield_server_availability
	SET inactive_fields_of_type = inactive_fields_of_type - 1
	WHERE server_id = in_server_id AND spicefield_type_id = in_spicefield_type_id;

	UPDATE spicefield_types
	SET current_globally_active = current_globally_active + 1
	WHERE spicefield_type_id = in_spicefield_type_id;

	RETURN TRUE;
END
$function$
