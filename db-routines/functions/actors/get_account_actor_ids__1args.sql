-- get_account_actor_ids(in_account_id bigint) -> dune.playeractorids
-- oid: 58269  kind: FUNCTION  category: actors

CREATE OR REPLACE FUNCTION dune.get_account_actor_ids(in_account_id bigint)
 RETURNS dune.playeractorids
 LANGUAGE plpgsql
AS $function$
BEGIN
    return (
        select (player_controller_id, player_state_id, player_pawn_id)::PlayerActorIds from player_state
        where account_id = in_account_id
        limit 1
    );
END
$function$
