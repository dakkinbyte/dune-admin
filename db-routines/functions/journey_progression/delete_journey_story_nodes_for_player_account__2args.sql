-- delete_journey_story_nodes_for_player_account(in_account_id bigint, in_story_node_ids text[]) -> void
-- oid: 58221  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.delete_journey_story_nodes_for_player_account(in_account_id bigint, in_story_node_ids text[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM journey_story_node
	WHERE story_node_id = ANY(in_story_node_ids)
	AND account_id = in_account_id;

	DELETE FROM journey_story_node_cooldown
	WHERE story_node_id = ANY(in_story_node_ids)
	AND account_id = in_account_id;
END $function$
