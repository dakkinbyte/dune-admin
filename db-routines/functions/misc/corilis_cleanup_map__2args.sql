-- corilis_cleanup_map(in_server_info dune.serverinfo, in_map_info dune.coriolismapinfo) -> void
-- oid: 58177  kind: FUNCTION  category: misc

CREATE OR REPLACE FUNCTION dune.corilis_cleanup_map(in_server_info dune.serverinfo, in_map_info dune.coriolismapinfo)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	PERFORM delete_markers_for_all_players(in_map_info.marker_types_to_keep, in_server_info.map);

	IF in_map_info.should_clear_surveyed_areas
	THEN
		DELETE FROM map_areas WHERE map_name = in_server_info.map;
	END IF;

	IF in_map_info.is_outside_shieldwall
	THEN
		DELETE FROM resourcefield_state WHERE map = in_server_info.map;
	END IF;
END
$function$
