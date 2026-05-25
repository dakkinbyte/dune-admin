-- update_journey_story_ids(old_story_ids text[], new_story_ids text[]) -> void
-- oid: 58625  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.update_journey_story_ids(old_story_ids text[], new_story_ids text[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	index INT;
BEGIN
	IF array_length(old_story_ids, 1) != array_length(new_story_ids, 1) THEN
		RAISE EXCEPTION 'The length of the array of old IDs does not match the length of the array of new IDs - they must both have the same length';
	END IF;

	FOR index in 1 .. array_length(old_story_ids, 1) LOOP
		UPDATE journey_story_node
		SET story_node_id = new_story_ids[index]
		WHERE story_node_id = old_story_ids[index];

		UPDATE journey_story_node_cooldown
		SET story_node_id = new_story_ids[index]
		WHERE story_node_id = old_story_ids[index];
	END LOOP;
END;
$function$
