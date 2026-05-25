-- admin_move_offline_player(in_fls_id text, in_target_partition_name text, in_target_location dune.vector) -> void
-- oid: 58136  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.admin_move_offline_player(in_fls_id text, in_target_partition_name text, in_target_location dune.vector)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
	if not (select is_player_offline(in_fls_id)) then
		raise exception 'Player must be Offline';
	end if;

	if not exists(select 1 from world_partition where label = in_target_partition_name) then
		raise exception 'Partition with name % not found', in_target_partition_name;
	end if;

	perform (with target_partition as (
		select partition_id, map, dimension_index
		from world_partition
		where label = in_target_partition_name
		limit 1
	)
	select admin_move_offline_player_to_partition(in_fls_id, target_partition.partition_id, in_target_location)
	from target_partition);
end
$function$
