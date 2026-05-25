-- get_player_partition_id(in_fls_id text) -> bigint
-- oid: 58343  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_player_partition_id(in_fls_id text)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Only the player pawn actually travels and gets it's partition id updated
    return (
        select actors.partition_id
        from accounts as acc
        join player_state as ps on ps.account_id = acc.id
        join actors on actors.id = ps.player_pawn_id
        where acc.user = in_fls_id
    );
END
$function$
