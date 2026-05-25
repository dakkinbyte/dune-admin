-- get_player_online_state_within_grace_period_for_each_server() -> TABLE(fls_id text, previous_partition_id bigint, current_server_id text, online_status dune.playerconnectionstatus, within_grace_period boolean, last_disconnect timestamp without time zone, demo_playtime_seconds integer, logoff_persistence_end_time timestamp without time zone, party_id bigint)
-- oid: 58341  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_player_online_state_within_grace_period_for_each_server()
 RETURNS TABLE(fls_id text, previous_partition_id bigint, current_server_id text, online_status dune.playerconnectionstatus, within_grace_period boolean, last_disconnect timestamp without time zone, demo_playtime_seconds integer, logoff_persistence_end_time timestamp without time zone, party_id bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY SELECT accounts.user as fls_id, player_state.previous_server_partition_id as previous_partition_id, player_state.server_id as current_server_id, player_state.online_status as online_status, player_state.reconnect_grace_period_end > (now() AT TIME ZONE 'UTC')::TIMESTAMP as within_grace_period, (player_state.last_avatar_activity AT TIME ZONE 'UTC')::TIMESTAMP as last_disconnect, demo_users.demo_playtime_seconds, (player_state.logoff_persistence_end_time)::TIMESTAMP as logoff_persistence_end_time, party_members.party_id
    FROM player_state
    LEFT JOIN accounts ON accounts.id = player_state.account_id
    LEFT JOIN demo_users ON accounts.user = demo_users.fls_id
    LEFT JOIN party_members ON player_state.player_controller_id = party_members.player_id;
END
$function$
