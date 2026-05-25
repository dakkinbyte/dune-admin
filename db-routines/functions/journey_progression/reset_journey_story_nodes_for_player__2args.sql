-- reset_journey_story_nodes_for_player(in_player_id text, in_story_node_ids text[]) -> void
-- oid: 58530  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.reset_journey_story_nodes_for_player(in_player_id text, in_story_node_ids text[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	IF NOT is_player_offline(in_player_id) THEN
		RAISE EXCEPTION 'Cannot execute query because the player is online - they must be offline in order for the journey data to be updated correctly without risking it being overwritten by player actions.';
	END IF;

	UPDATE journey_story_node
	SET complete_condition_state = jsonb_object(ARRAY[]::text[])
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
