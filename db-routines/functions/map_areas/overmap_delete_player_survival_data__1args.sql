-- overmap_delete_player_survival_data(in_player_id bigint) -> void
-- oid: 58479  kind: FUNCTION  category: map_areas

CREATE OR REPLACE FUNCTION dune.overmap_delete_player_survival_data(in_player_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM overmap_players WHERE player_id = in_player_id;
END $function$
