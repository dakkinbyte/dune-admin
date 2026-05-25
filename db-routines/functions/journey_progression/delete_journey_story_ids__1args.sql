-- delete_journey_story_ids(story_ids text[]) -> void
-- oid: 58217  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.delete_journey_story_ids(story_ids text[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM journey_story_node
	WHERE story_node_id = ANY(story_ids);

	DELETE FROM journey_story_node_cooldown
	WHERE story_node_id = ANY(story_ids);
END;
$function$
