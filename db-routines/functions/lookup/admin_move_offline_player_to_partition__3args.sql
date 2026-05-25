-- admin_move_offline_player_to_partition(in_fls_id text, in_target_partition_id bigint, in_target_location dune.vector) -> void
-- oid: 58137  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.admin_move_offline_player_to_partition(in_fls_id text, in_target_partition_id bigint, in_target_location dune.vector)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
	if not (select is_player_offline(in_fls_id)) then
		-- CAVEAT: DirectorDbApi.TryMoveOfflinePlayerToPartition depends on this string.
		raise exception 'Player must be Offline';
	end if;

	if not exists(select 1 from world_partition where partition_id = in_target_partition_id) then
		raise exception 'Partition with ID % not found', in_target_partition_id;
	end if;

	raise notice 'Moving player % to partition % location x=%, y=%, z=%', in_fls_id, in_target_partition_id, in_target_location.x, in_target_location.y, in_target_location.z;

	with target_partition as (
		select partition_id, map, dimension_index
		from world_partition
		where partition_id = in_target_partition_id
		limit 1
	), target_pawn_id as (
		select player_state.player_pawn_id as id
		from accounts, player_state
		where accounts.user = in_fls_id and accounts.id = player_state.account_id
		limit 1
	), update_overmap_player_location as (
		select
			case 
		        when target_partition.map = 'Overmap' then overmap_save_player_survival_data(target_pawn_id.id, null, false, in_target_location)
		        else null
    		end
		from target_pawn_id, target_partition
	)
	update actors
		set
			transform = (in_target_location, (transform).rotation),
			map = upgrade_map_name(target_partition.map),
			dimension_index = target_partition.dimension_index,
			partition_id = target_partition.partition_id
		from
			target_pawn_id, target_partition, update_overmap_player_location
		where actors.id = target_pawn_id.id;
end
$function$
