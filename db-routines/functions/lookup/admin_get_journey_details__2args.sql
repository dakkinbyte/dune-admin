-- admin_get_journey_details(in_player_id text, in_story_node_id text) -> TABLE(out_story_node_id text, out_override_reward_block boolean, out_has_pending_reward boolean, out_complete_condition_state jsonb, out_reveal_condition_state jsonb, out_fail_condition_state jsonb, out_metadata_state jsonb, out_reset_group dune.journeystoryresetgroup)
-- oid: 58133  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.admin_get_journey_details(in_player_id text, in_story_node_id text DEFAULT '%%'::text)
 RETURNS TABLE(out_story_node_id text, out_override_reward_block boolean, out_has_pending_reward boolean, out_complete_condition_state jsonb, out_reveal_condition_state jsonb, out_fail_condition_state jsonb, out_metadata_state jsonb, out_reset_group dune.journeystoryresetgroup)
 LANGUAGE sql
AS $function$
	select story_node_id, override_reward_block, has_pending_reward, complete_condition_state, reveal_condition_state, fail_condition_state, metadata_state, reset_group
	from journey_story_node
	where story_node_id like in_story_node_id
	and account_id in (
		select id
		from accounts a
		where a.user = in_player_id
	);
$function$
