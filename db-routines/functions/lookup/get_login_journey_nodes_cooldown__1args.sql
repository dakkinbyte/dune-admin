-- get_login_journey_nodes_cooldown(in_account_id bigint) -> dune.journeynodecooldowninfo[]
-- oid: 58319  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_login_journey_nodes_cooldown(in_account_id bigint)
 RETURNS dune.journeynodecooldowninfo[]
 LANGUAGE plpgsql
AS $function$
DECLARE
    result JourneyNodeCooldownInfo[];
BEGIN
    SELECT
        array_agg(
            (
             res.story_node_id,
             res.time_to_expire
            )::JourneyNodeCooldownInfo
        )
    INTO result
    FROM journey_story_node_cooldown res
    WHERE res.account_id = in_account_id;

    RETURN result;
END
$function$
