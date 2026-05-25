-- save_journey_story_nodes(in_account_id bigint, in_journey_data dune.savejourneydata[]) -> void
-- oid: 58549  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.save_journey_story_nodes(in_account_id bigint, in_journey_data dune.savejourneydata[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	INSERT INTO journey_story_node(account_id, story_node_id, override_reward_block, has_pending_reward, complete_condition_state, reveal_condition_state, fail_condition_state, metadata_state, reset_group)
		SELECT in_account_id, story_node_id, override_reward_block, has_pending_reward, to_jsonb(completion_state_string), to_jsonb(reveal_state_string), to_jsonb(fail_state_string), to_jsonb(metadata_state_string), reset_group
		FROM UNNEST(in_journey_data)
	ON CONFLICT ON CONSTRAINT journey_story_node_pkey
		DO UPDATE SET
			override_reward_block = EXCLUDED.override_reward_block,
            has_pending_reward = EXCLUDED.has_pending_reward,
			complete_condition_state = EXCLUDED.complete_condition_state,
			reveal_condition_state = EXCLUDED.reveal_condition_state,
			fail_condition_state = EXCLUDED.fail_condition_state,
			metadata_state = EXCLUDED.metadata_state,
			reset_group = EXCLUDED.reset_group;
END
$function$
