-- save_actor_dislocation(in_actor_id bigint, in_current_server_info dune.serverinfo, in_target_location dune.vector, in_target_dimension_index integer) -> void
-- oid: 58540  kind: FUNCTION  category: actors

CREATE OR REPLACE FUNCTION dune.save_actor_dislocation(in_actor_id bigint, in_current_server_info dune.serverinfo, in_target_location dune.vector, in_target_dimension_index integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
	update actors
		set
			transform = (in_target_location, (transform).rotation),
			dimension_index = in_target_dimension_index,
			partition_id = null
		where id = in_actor_id
			and map = (in_current_server_info).map
			and dimension_index = (in_current_server_info).dimension_index
			and (
				partition_id is null
				or (in_current_server_info).partition_id is null
				or partition_id = (in_current_server_info).partition_id
			);
end
$function$
