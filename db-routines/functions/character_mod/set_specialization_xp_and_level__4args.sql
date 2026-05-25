-- set_specialization_xp_and_level(in_player_id bigint, in_track_type dune.specializationtracktype, in_xp_amount integer, in_level real) -> void
-- oid: 58596  kind: FUNCTION  category: character_mod

CREATE OR REPLACE FUNCTION dune.set_specialization_xp_and_level(in_player_id bigint, in_track_type dune.specializationtracktype, in_xp_amount integer, in_level real)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	INSERT INTO specialization_tracks (player_id, track_type, xp_amount, level) VALUES (in_player_id, in_track_type, in_xp_amount, in_level)
	ON CONFLICT(player_id, track_type) DO UPDATE SET xp_amount = in_xp_amount, level = in_level;
END $function$
