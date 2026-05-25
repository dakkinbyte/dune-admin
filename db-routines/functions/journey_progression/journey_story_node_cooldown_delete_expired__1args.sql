-- journey_story_node_cooldown_delete_expired(in_time_to_check timestamp without time zone) -> void
-- oid: 58398  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.journey_story_node_cooldown_delete_expired(in_time_to_check timestamp without time zone)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM journey_story_node_cooldown WHERE time_to_expire < in_time_to_check;
END $function$
