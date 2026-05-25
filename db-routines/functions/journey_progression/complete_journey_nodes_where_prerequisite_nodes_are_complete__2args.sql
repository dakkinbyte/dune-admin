-- complete_journey_nodes_where_prerequisite_nodes_are_complete(story_ids_to_complete text[], prerequisite_completed_story_ids text[]) -> void
-- oid: 58175  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.complete_journey_nodes_where_prerequisite_nodes_are_complete(story_ids_to_complete text[], prerequisite_completed_story_ids text[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	IF ARRAY_LENGTH(story_ids_to_complete, 1) = 0 OR ARRAY_LENGTH(prerequisite_completed_story_ids, 1) = 0 THEN
		RAISE EXCEPTION 'The story ids to complete array and/or the prerequisite completed story ids array is empty - neither array may be empty';
	END IF;

	WITH account_ids_to_modify AS (
		SELECT account_id
		FROM journey_story_node
		WHERE story_node_id = ANY(prerequisite_completed_story_ids)
		AND complete_condition_state = to_jsonb(true)
		GROUP BY account_id
		HAVING COUNT(DISTINCT story_node_id) = ARRAY_LENGTH(prerequisite_completed_story_ids, 1)
	)
	INSERT INTO journey_story_node(account_id, story_node_id, override_reward_block, has_pending_reward, complete_condition_state, reveal_condition_state, metadata_state, reset_group, fail_condition_state)
	SELECT ids.account_id, completed_node.story_node_id, false, false, to_jsonb(true), to_jsonb(true), '{}', 'Default', '{}'
	FROM account_ids_to_modify AS ids
	CROSS JOIN (
		SELECT story_node_id
		FROM UNNEST(story_ids_to_complete) AS story_node_id
	) completed_node(story_node_id)
	ON CONFLICT ON CONSTRAINT journey_story_node_pkey
		DO UPDATE SET
			override_reward_block = EXCLUDED.override_reward_block,
            has_pending_reward = EXCLUDED.has_pending_reward,
			complete_condition_state = EXCLUDED.complete_condition_state,
			reveal_condition_state = EXCLUDED.reveal_condition_state;
END;
$function$
