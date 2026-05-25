-- load_dialogue_data(in_player_controller_id bigint, OUT met_npcs text[], OUT taken_nodes integer[]) -> record
-- oid: 58451  kind: FUNCTION  category: dialogue

CREATE OR REPLACE FUNCTION dune.load_dialogue_data(in_player_controller_id bigint, OUT met_npcs text[], OUT taken_nodes integer[])
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    SELECT ARRAY_AGG(npc_name)
    INTO met_npcs
    FROM dialogue_met_npcs
    WHERE player_id = in_player_controller_id;

    SELECT ARRAY_AGG(node_id)
    INTO taken_nodes
    FROM dialogue_taken_nodes
    WHERE player_id = in_player_controller_id;
END
$function$
