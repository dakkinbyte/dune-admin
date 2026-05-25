-- set_all_inactive_players_in_farm_offline() -> void
-- oid: 58588  kind: FUNCTION  category: farm

CREATE OR REPLACE FUNCTION dune.set_all_inactive_players_in_farm_offline()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE player_state SET online_status = 'Offline', last_avatar_activity = current_timestamp WHERE online_status <> 'Offline' AND server_id NOT IN (SELECT * FROM active_server_ids);
END
$function$
