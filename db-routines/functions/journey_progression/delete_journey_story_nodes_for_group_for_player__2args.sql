-- delete_journey_story_nodes_for_group_for_player(in_account_id bigint, in_reset_group dune.journeystoryresetgroup) -> void
-- oid: 58219  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.delete_journey_story_nodes_for_group_for_player(in_account_id bigint, in_reset_group dune.journeystoryresetgroup)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM journey_story_node_cooldown
	WHERE story_node_id IN (
		SELECT story_node_id
		FROM journey_story_node a
		WHERE a.account_id = in_account_id AND a.reset_group = in_reset_group
	)
	AND account_id = in_account_id;

	DELETE FROM journey_story_node
	WHERE reset_group = in_reset_group AND account_id = in_account_id;
END $function$
