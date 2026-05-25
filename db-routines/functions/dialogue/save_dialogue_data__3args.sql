-- save_dialogue_data(in_player_controller_id bigint, in_met_npcs text[], in_taken_nodes integer[]) -> void
-- oid: 58546  kind: FUNCTION  category: dialogue

CREATE OR REPLACE FUNCTION dune.save_dialogue_data(in_player_controller_id bigint, in_met_npcs text[], in_taken_nodes integer[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO dialogue_met_npcs(player_id, npc_name) SELECT in_player_controller_id, unnest(in_met_npcs)
    ON CONFLICT DO NOTHING;

    INSERT INTO dialogue_taken_nodes(player_id, node_id) SELECT in_player_controller_id, unnest(in_taken_nodes)
    ON CONFLICT DO NOTHING;
END
$function$
