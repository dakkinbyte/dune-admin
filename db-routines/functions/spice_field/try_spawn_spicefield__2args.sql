-- try_spawn_spicefield(in_source_server_id text, in_spicefield_id integer) -> boolean
-- oid: 58612  kind: FUNCTION  category: spice_field

CREATE OR REPLACE FUNCTION dune.try_spawn_spicefield(in_source_server_id text, in_spicefield_id integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
begin
	perform spicefield_type_id from spicefield_types as t
		where t.spicefield_type_id = in_spicefield_id and t.is_spawning_active is true and t.current_globally_active < t.max_globally_active;
	if not found then
		return false;
	end if;

	update spicefield_server_availability
	set requested_spawned_of_type = requested_spawned_of_type - 1
	where server_id = in_source_server_id and spicefield_type_id = in_spicefield_id;

	update spicefield_types
	set current_globally_active = current_globally_active + 1, current_globally_primed = current_globally_primed -1
	where spicefield_type_id = in_spicefield_id;

	return true;
	commit;
end $function$
