-- get_login_journey_nodes(in_account_id bigint) -> dune.journeynodeinfo[]
-- oid: 58318  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_login_journey_nodes(in_account_id bigint)
 RETURNS dune.journeynodeinfo[]
 LANGUAGE plpgsql
AS $function$
DECLARE
    result JourneyNodeInfo[];
BEGIN
    SELECT
        array_agg(
            (
             res.story_node_id,
             res.override_reward_block,
             res.has_pending_reward,
             res.complete_condition_state,
             res.reveal_condition_state,
             res.fail_condition_state,
             res.metadata_state,
             res.reset_group
            )::JourneyNodeInfo
        )
    INTO result
    FROM journey_story_node res
    WHERE res.account_id = in_account_id;

    RETURN result;
END
$function$
