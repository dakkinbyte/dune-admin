-- player_state_update(in_data dune.playerstateupdatedata[]) -> void
-- oid: 58495  kind: FUNCTION  category: character_mod

CREATE OR REPLACE FUNCTION dune.player_state_update(in_data dune.playerstateupdatedata[])
 RETURNS void
 LANGUAGE sql
AS $function$
    -- online -> offline
    with
        update_data as (select * from unnest(in_data))
        update encrypted_player_state as ps
            set online_status = update_data.online_status
            from update_data
            where ps.player_controller_id = update_data.player_controller_id
                and ps.server_id = update_data.current_server_id -- make sure we don't update if the player is already online somewhere else
                and update_data.online_status != 'Online'
                and ps.online_status != update_data.online_status; -- avoid unnecessary data changes

    -- offline -> online
	with
		update_data as (select * from unnest(in_data))
        update encrypted_player_state as ps
            set online_status = update_data.online_status,
                server_id = update_data.current_server_id
            from update_data
            where ps.player_controller_id = update_data.player_controller_id
              and update_data.online_status = 'Online'
              and (ps.server_id is null or ps.server_id != update_data.current_server_id or ps.online_status != update_data.online_status); -- avoid unnecessary data changes

	with
		update_data as (select * from unnest(in_data))
        update encrypted_player_state as ps
            set reconnect_grace_period_end = update_data.reconnect_grace_period_end
            from update_data
            where ps.player_controller_id = update_data.player_controller_id
                and not update_data.reconnect_grace_period_end is null;

	with
		update_data as (select * from unnest(in_data))
        update encrypted_player_state as ps
            set
                last_avatar_activity = (update_data.on_disconnect).last_online_time AT TIME ZONE 'UTC',
                previous_server_partition_id = (update_data.on_disconnect).previous_server_partition_id
            from update_data
            where ps.player_controller_id = update_data.player_controller_id
                and not update_data.on_disconnect is null;
$function$
