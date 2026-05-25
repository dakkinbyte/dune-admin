-- save_aborted_authority_transfer_actors(in_actor_ids bigint[], in_partition_id bigint) -> void
-- oid: 58539  kind: FUNCTION  category: actors

CREATE OR REPLACE FUNCTION dune.save_aborted_authority_transfer_actors(in_actor_ids bigint[], in_partition_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO actor_state(actor_id, state)
        SELECT a.id, 'AbortedAuthorityTransfer'
        FROM actors AS a
        WHERE a.id = ANY(in_actor_ids) AND a.partition_id = in_partition_id
    ON CONFLICT DO NOTHING;
END
$function$
