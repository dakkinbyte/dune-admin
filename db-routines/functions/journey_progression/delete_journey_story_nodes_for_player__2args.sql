-- delete_journey_story_nodes_for_player(in_player_id text, in_story_node_ids text[]) -> void
-- oid: 58220  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.delete_journey_story_nodes_for_player(in_player_id text, in_story_node_ids text[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM journey_story_node
	WHERE story_node_id = ANY(in_story_node_ids)
	AND account_id IN (
		SELECT id
		FROM accounts a
		WHERE a.user = in_player_id
	);

	DELETE FROM journey_story_node_cooldown
	WHERE story_node_id = ANY(in_story_node_ids)
	AND account_id IN (
		SELECT id
		FROM accounts a
		WHERE a.user = in_player_id
	);
END $function$
