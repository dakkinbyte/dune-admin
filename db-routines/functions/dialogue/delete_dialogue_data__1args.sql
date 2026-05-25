-- delete_dialogue_data(in_player_controller_id bigint) -> void
-- oid: 58212  kind: FUNCTION  category: dialogue

CREATE OR REPLACE FUNCTION dune.delete_dialogue_data(in_player_controller_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM dialogue_met_npcs
    WHERE player_id = in_player_controller_id;

    DELETE FROM dialogue_taken_nodes
    WHERE player_id = in_player_controller_id;
END
$function$
