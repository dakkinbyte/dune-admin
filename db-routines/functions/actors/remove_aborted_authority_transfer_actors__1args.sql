-- remove_aborted_authority_transfer_actors(in_partition_id bigint) -> SETOF dune.actorspawninfo
-- oid: 58515  kind: FUNCTION  category: actors

CREATE OR REPLACE FUNCTION dune.remove_aborted_authority_transfer_actors(in_partition_id bigint)
 RETURNS SETOF dune.actorspawninfo
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
        WITH removed_actors AS (
            DELETE FROM actor_state WHERE actor_state.state = 'AbortedAuthorityTransfer'
            RETURNING actor_state.actor_id
        )
        SELECT a.id, a.class AS class_name, a.transform, a.partition_id, a.dimension_index
        FROM actors AS a
        INNER JOIN removed_actors ON a.id = removed_actors.actor_id
        WHERE a.partition_id = in_partition_id;
END
$function$
