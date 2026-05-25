-- reset_specialization_tracks(in_player_id bigint) -> void
-- oid: 58533  kind: FUNCTION  category: character_mod

CREATE OR REPLACE FUNCTION dune.reset_specialization_tracks(in_player_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM specialization_tracks WHERE player_id = in_player_id;
END $function$
