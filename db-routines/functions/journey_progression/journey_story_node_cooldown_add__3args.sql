-- journey_story_node_cooldown_add(in_account_id bigint, in_story_node_id text, in_time_to_expire timestamp without time zone) -> void
-- oid: 58397  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.journey_story_node_cooldown_add(in_account_id bigint, in_story_node_id text, in_time_to_expire timestamp without time zone)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	INSERT INTO journey_story_node_cooldown(account_id, story_node_id, time_to_expire)
	VALUES(in_account_id, in_story_node_id, in_time_to_expire);
END $function$
