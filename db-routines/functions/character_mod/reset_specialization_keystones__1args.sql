-- reset_specialization_keystones(in_player_id bigint) -> void
-- oid: 58532  kind: FUNCTION  category: character_mod

CREATE OR REPLACE FUNCTION dune.reset_specialization_keystones(in_player_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM purchased_specialization_keystones WHERE player_id = in_player_id;
END $function$
