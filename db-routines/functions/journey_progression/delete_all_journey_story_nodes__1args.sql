-- delete_all_journey_story_nodes(in_account_id bigint) -> void
-- oid: 58206  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.delete_all_journey_story_nodes(in_account_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM journey_story_node WHERE account_id = in_account_id;
END $function$
