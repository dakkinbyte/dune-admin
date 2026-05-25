-- delete_all_tutorial_entries(in_player_id bigint) -> void
-- oid: 58208  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.delete_all_tutorial_entries(in_player_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    DELETE FROM tutorial_per_player WHERE tutorial_per_player.player_id = in_player_id;
END
$function$
