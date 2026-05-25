-- reveal_journey_story_nodes_for_player(in_player_id text, in_story_node_ids text[]) -> void
-- oid: 58538  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.reveal_journey_story_nodes_for_player(in_player_id text, in_story_node_ids text[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	IF NOT is_player_offline(in_player_id) THEN
		RAISE EXCEPTION 'Cannot execute query because the player is online - they must be offline in order for the journey data to be updated correctly without risking it being overwritten by player actions.';
	END IF;

	WITH player_account_id AS (
		SELECT id
		FROM accounts a
		WHERE a.user = in_player_id
	)
	INSERT INTO journey_story_node(account_id, story_node_id, override_reward_block, has_pending_reward, complete_condition_state, reveal_condition_state, fail_condition_state, metadata_state, reset_group)
	SELECT player_account_id.id, completed_node.story_node_id, completed_node.override_reward_block, completed_node.has_pending_reward, completed_node.complete_condition_state, completed_node.reveal_condition_state, completed_node.fail_condition_state, completed_node.metadata_state, completed_node.reset_group
	FROM player_account_id 
	CROSS JOIN (
		SELECT story_node_id, false, false, jsonb_object(ARRAY[]::text[]), to_jsonb(true), jsonb_object(ARRAY[]::text[]), jsonb_object(ARRAY[]::text[]), 'Default'::JourneyStoryResetGroup
		FROM UNNEST(in_story_node_ids) AS story_node_id
	) completed_node(story_node_id, override_reward_block, has_pending_reward, complete_condition_state, reveal_condition_state, fail_condition_state, metadata_state, reset_group)
	ON CONFLICT ON CONSTRAINT journey_story_node_pkey
		DO UPDATE SET
			reveal_condition_state = EXCLUDED.reveal_condition_state,
			metadata_state = EXCLUDED.metadata_state;
END $function$
