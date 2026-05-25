-- is_player_offline(in_fls_id text) -> boolean
-- oid: 58394  kind: FUNCTION  category: lookup
-- comment: Return true if player is marked as offline, taking into account server crashing before players online state was updated in DB.

CREATE OR REPLACE FUNCTION dune.is_player_offline(in_fls_id text)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
    has_state int;
    is_offline boolean;
begin
    -- If there's no player_state row for this account, treat the player as offline
    select count(*) into has_state
    from player_state ps
    join accounts a on a.id = ps.account_id
    where a.user = in_fls_id;

    if has_state = 0 then
        return true;
    end if;

    select exists(
        select 1
        from player_state ps
        join accounts a on a.id = ps.account_id
        where a.user = in_fls_id
          and (
            ps.online_status = 'Offline'
            -- Player is treated as offline if last played server is offline/unavailable, or not set at all
            or (ps.server_id is null or ps.server_id not in (select * from active_server_ids))
          )
    ) into is_offline;

    return is_offline;
end
$function$
