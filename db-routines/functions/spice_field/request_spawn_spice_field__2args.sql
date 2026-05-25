-- request_spawn_spice_field(in_server_id text, in_spicefield_type_id integer) -> void
-- oid: 58527  kind: FUNCTION  category: spice_field

CREATE OR REPLACE FUNCTION dune.request_spawn_spice_field(in_server_id text, in_spicefield_type_id integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    PERFORM spicefield_type_id FROM spicefield_types AS t
		WHERE t.spicefield_type_id = in_spicefield_type_id AND t.is_spawning_active IS TRUE AND t.current_globally_primed < t.max_globally_primed AND t.current_globally_active < t.max_globally_active;
	IF NOT FOUND THEN
		RETURN;
	END IF;

	UPDATE spicefield_server_availability
	SET requested_spawned_of_type = requested_spawned_of_type + 1
	WHERE server_id = in_server_id AND spicefield_type_id = in_spicefield_type_id;
END; $function$
