-- save_player(in_player dune.playerdescription) -> boolean
-- oid: 58562  kind: FUNCTION  category: player_persistence

CREATE OR REPLACE FUNCTION dune.save_player(in_player dune.playerdescription)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
    fgl_entity FglEntity;
    player_actors ActorDescription[];
    all_serials_are_same Boolean;
    should_save_all_actors Boolean;
BEGIN
    player_actors := array[in_player.state, in_player.controller];

    IF NOT in_player.pawn IS NULL THEN
        foreach fgl_entity in array (in_player).pawn.generic_data.entities loop
            if fgl_entity.slot_name in ('DuneCharacter', 'PersonalCrafting') and fgl_entity.components_json = '{}'::jsonb then
                raise exception 'invalid player save with empty fgl state for pawn';
            end if;
        end loop;
        player_actors := player_actors || in_player.pawn;
    END IF;

    with
        ids_and_serials as (
            select
                input.serial = (in_player.controller).serial as is_matching_serial,
                input.serial >= existing.serial as should_save
            from unnest(player_actors) as input join actors as existing using (id)
        )
        select bool_and(is_matching_serial), bool_and(should_save) from ids_and_serials
        into all_serials_are_same, should_save_all_actors;

    IF NOT all_serials_are_same THEN
        raise exception 'serial: serial mismatch between the player actors';
    end if;

    -- Demo time remaining
    IF in_player.demo_playtime_seconds IS NOT NULL THEN
        UPDATE demo_users
        SET demo_playtime_seconds = in_player.demo_playtime_seconds
        WHERE fls_id = (
            SELECT acc.user FROM accounts AS acc
            WHERE acc.id = in_player.id
        );
    END IF;

    -- Demo state
    IF in_player.demo_state IS NOT NULL THEN
        UPDATE demo_users
		SET demo_state = in_player.demo_state
		WHERE fls_id = (
            SELECT acc.user FROM accounts AS acc
            WHERE acc.id = in_player.id
        );
    END IF;

    IF NOT should_save_all_actors THEN
        return false;
    end if;

    -- Allow saving of the player without having a player character (pawn)
    PERFORM save_actors(in_player.pawn_server_info, player_actors);

    PERFORM update_respawn_locations(in_player.id, (in_player.respawn_info).locations);

    PERFORM update_death_location(in_player.pawn, in_player.pawn_server_info, in_player.life_state);

    UPDATE player_state
        SET pending_respawn_location_id=(in_player.respawn_info).pending_location_id, life_state=in_player.life_state
        WHERE account_id=in_player.id;

    return true;
END;
$function$
