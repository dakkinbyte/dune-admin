-- get_player_pawn(in_account_id bigint) -> TABLE(description dune.actordescription, server_info dune.serverinfo, player_tags text[])
-- oid: 58344  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_player_pawn(in_account_id bigint)
 RETURNS TABLE(description dune.actordescription, server_info dune.serverinfo, player_tags text[])
 LANGUAGE plpgsql
AS $function$
BEGIN
    return query
        with id as (select player_pawn_id as id from player_state where account_id = in_account_id limit 1),
        tags as (select array_agg(tag) from player_tags where account_id = in_account_id)
            select load_full_actors(array[id]) as description, get_actor_server_info(id) as server_info, (select * from tags) as player_tags
            from id limit 1;
END
$function$
