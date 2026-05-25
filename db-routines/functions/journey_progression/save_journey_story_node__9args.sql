-- save_journey_story_node(in_account_id bigint, in_story_node_id text, in_override_reward_block boolean, in_has_pending_reward boolean, in_complete_condition_state jsonb, in_reveal_condition_state jsonb, in_fail_condition_state jsonb, in_metadata_state jsonb, in_reset_group dune.journeystoryresetgroup) -> void
-- oid: 58548  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.save_journey_story_node(in_account_id bigint, in_story_node_id text, in_override_reward_block boolean, in_has_pending_reward boolean, in_complete_condition_state jsonb, in_reveal_condition_state jsonb, in_fail_condition_state jsonb, in_metadata_state jsonb, in_reset_group dune.journeystoryresetgroup)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	INSERT INTO journey_story_node(account_id, story_node_id, override_reward_block, has_pending_reward, complete_condition_state, reveal_condition_state, fail_condition_state, metadata_state, reset_group)
	VALUES(in_account_id, in_story_node_id, in_override_reward_block, in_has_pending_reward, in_complete_condition_state, in_reveal_condition_state, in_fail_condition_state, in_metadata_state, in_reset_group)
	ON CONFLICT (account_id, story_node_id)
	DO UPDATE SET
        override_reward_block = in_override_reward_block,
        has_pending_reward = in_has_pending_reward,
        complete_condition_state = in_complete_condition_state,
        reveal_condition_state = in_reveal_condition_state,
		fail_condition_state = in_fail_condition_state,
		metadata_state = in_metadata_state,
		reset_group = in_reset_group;
END $function$
