-- coriolis_cleanup_farm(in_server_info dune.serverinfo, in_map_info dune.coriolismapinfo) -> void
-- oid: 58178  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.coriolis_cleanup_farm(in_server_info dune.serverinfo, in_map_info dune.coriolismapinfo)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM lore_pickups_temporary;
	DELETE FROM consumed_temporary_per_player_lore;
	UPDATE player_state SET is_coriolis_processed = FALSE;
END
$function$
