-- gather_removed_accounts_that_left_orphaned_actors_on_server(in_server_info dune.serverinfo) -> TABLE(account_id bigint, removal_reason text, actors_left dune.orphanedplayeractorinfo[])
-- oid: 58268  kind: FUNCTION  category: actors

CREATE OR REPLACE FUNCTION dune.gather_removed_accounts_that_left_orphaned_actors_on_server(in_server_info dune.serverinfo)
 RETURNS TABLE(account_id bigint, removal_reason text, actors_left dune.orphanedplayeractorinfo[])
 LANGUAGE plpgsql
AS $function$
BEGIN
    return query with
        orphaned_actors_per_account as (
            SELECT
                a.owner_account_id as account_id,
                array_agg((a.id, a.class)::OrphanedPlayerActorInfo) as actors_left
            FROM actors as a
            WHERE
                -- not is null instead of is not null to match the index expression
                not a.owner_account_id is null
                AND NOT EXISTS(select 1 from accounts where id=owner_account_id)
                AND server_info_match(a, in_server_info)
            GROUP BY a.owner_account_id
        )
        select orphans.account_id, log.reason, orphans.actors_left
            from orphaned_actors_per_account as orphans left join account_removal_log as log using (account_id);
END
$function$
