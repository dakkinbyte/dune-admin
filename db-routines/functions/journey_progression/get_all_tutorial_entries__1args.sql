-- get_all_tutorial_entries(in_player_id bigint) -> TABLE(tutorial_id smallint, tutorial_state smallint)
-- oid: 58283  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.get_all_tutorial_entries(in_player_id bigint)
 RETURNS TABLE(tutorial_id smallint, tutorial_state smallint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY SELECT tutorial_per_player.tutorial_id, tutorial_per_player.tutorial_state FROM tutorial_per_player WHERE tutorial_per_player.player_id = in_player_id;
END
$function$
