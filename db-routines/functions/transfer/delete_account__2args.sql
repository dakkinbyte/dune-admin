-- delete_account(in_user_id text, in_reason text) -> boolean
-- oid: 58198  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune.delete_account(in_user_id text, in_reason text)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
    was_found Boolean;
BEGIN
    WITH referenced_actor_ids as (
        SELECT ARRAY[player_controller_id, player_pawn_id, player_state_id] as ids
            FROM player_state ps JOIN accounts a ON (ps.account_id = a.id)
            WHERE a.user = in_user_id
    ),
    deleted_actors AS
    (
        DELETE FROM actors USING referenced_actor_ids WHERE id IN (SELECT id FROM actors WHERE id = ANY(referenced_actor_ids.ids) ORDER BY id FOR UPDATE) returning id
    ),
    selected_respawn_beacons AS
    (
        SELECT player_respawn_locations.locator_actor_id FROM player_respawn_locations
        INNER JOIN accounts ON accounts.id = player_respawn_locations.account_id
        WHERE accounts.user = in_user_id AND player_respawn_locations.group = 'RespawnBeacon'
    ),
    delete_respawn_beacons AS
    (
        DELETE FROM actors
        WHERE actors.id IN (SELECT * FROM selected_respawn_beacons)
    ),
    delete_accounts as (
        DELETE FROM accounts WHERE accounts.user = in_user_id returning id as account_id
    ),
    insert_into_removal_log as (
        insert into account_removal_log("fls_id", "account_id", "reason") select in_user_id, account_id, in_reason from delete_accounts
    ),
    delete_from_cascades as (
        SELECT referenced_actor_ids.ids[1] as id,
            guild_handle_actor_delete(referenced_actor_ids.ids[1]),
            remove_party_member(referenced_actor_ids.ids[1], 0::SMALLINT),
            ownership_handle_actor_delete(referenced_actor_ids.ids[1]),
            perform_notify_on_character_delete(in_user_id)
            FROM referenced_actor_ids
    )
    SELECT count(*) > 0 INTO was_found FROM delete_from_cascades;
    return was_found;
END;
$function$
