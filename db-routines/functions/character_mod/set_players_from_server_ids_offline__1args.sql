-- set_players_from_server_ids_offline(in_server_ids text[]) -> void
-- oid: 58595  kind: FUNCTION  category: character_mod

CREATE OR REPLACE FUNCTION dune.set_players_from_server_ids_offline(in_server_ids text[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE player_state SET online_status = 'Offline', last_avatar_activity = current_timestamp WHERE online_status <> 'Offline' AND server_id = ANY(in_server_ids);
END
$function$
