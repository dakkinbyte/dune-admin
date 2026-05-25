-- try_prime_spicefield(in_source_server_id text, in_spicefield_id integer) -> boolean
-- oid: 58610  kind: FUNCTION  category: spice_field

CREATE OR REPLACE FUNCTION dune.try_prime_spicefield(in_source_server_id text, in_spicefield_id integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
begin
	perform spicefield_type_id from spicefield_types as t
		where t.spicefield_type_id = in_spicefield_id and t.is_spawning_active is true and t.current_globally_primed < t.max_globally_primed and t.current_globally_active < t.max_globally_active;
	if not found then
		return false;
	end if;

	update spicefield_server_availability
	set inactive_fields_of_type = inactive_fields_of_type - 1
	where server_id = in_source_server_id and spicefield_type_id = in_spicefield_id;

	update spicefield_types
	set current_globally_primed = current_globally_primed + 1
	where spicefield_type_id = in_spicefield_id;

	return true;
	commit;
end $function$
