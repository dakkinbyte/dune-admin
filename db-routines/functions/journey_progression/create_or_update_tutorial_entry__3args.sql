-- create_or_update_tutorial_entry(in_player_id bigint, in_tutorial_id smallint, in_tutorial_state smallint) -> void
-- oid: 58184  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.create_or_update_tutorial_entry(in_player_id bigint, in_tutorial_id smallint, in_tutorial_state smallint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO tutorial_per_player("player_id", "tutorial_id", "tutorial_state") VALUES(in_player_id, in_tutorial_id, in_tutorial_state)
    ON CONFLICT (player_id, tutorial_id) DO UPDATE SET "player_id" = in_player_id, "tutorial_id" = in_tutorial_id, "tutorial_state" = in_tutorial_state
    WHERE tutorial_per_player.player_id = in_player_id AND tutorial_per_player.tutorial_id = in_tutorial_id;
END
$function$
