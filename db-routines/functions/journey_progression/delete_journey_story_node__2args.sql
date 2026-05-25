-- delete_journey_story_node(in_account_id bigint, in_story_node_id text) -> void
-- oid: 58218  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.delete_journey_story_node(in_account_id bigint, in_story_node_id text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM journey_story_node WHERE account_id = in_account_id AND story_node_id = in_story_node_id;
END $function$
