-- login_account(in_user_id text, in_funcom_id text, in_platform_id text, in_platform_name text, in_minimum_returning_player_time_seconds integer, in_character_name text, in_return_dimension_index integer, in_home_dimension_index integer) -> SETOF dune.playerdescription
-- oid: 58471  kind: FUNCTION  category: character_mod

CREATE OR REPLACE FUNCTION dune.login_account(in_user_id text, in_funcom_id text, in_platform_id text, in_platform_name text, in_minimum_returning_player_time_seconds integer, in_character_name text, in_return_dimension_index integer, in_home_dimension_index integer)
 RETURNS SETOF dune.playerdescription
 LANGUAGE plpgsql
AS $function$
DECLARE
    user_account_id BigInt;
BEGIN
    PERFORM update_returning_player_status(in_user_id, in_minimum_returning_player_time_seconds);

    return query with
        acc as (
            INSERT INTO encrypted_accounts("id", "user", "platform_id", "platform_name", "encrypted_funcom_id")
                VALUES (default, in_user_id, in_platform_id, in_platform_name, encrypt_user_data(in_funcom_id))
                ON CONFLICT ("user") DO UPDATE SET
                    encrypted_funcom_id = excluded.encrypted_funcom_id,
                    platform_id = excluded.platform_id,
                    platform_name = excluded.platform_name
                RETURNING id, encrypted_accounts.user
        ),
        actor_ids as (
            -- TODO: unite this with accounts. One table to rule them all (until we want multiple chars per account)
            SELECT
                coalesce(player_controller_id, nextval('actors_id_seq')) as controller,
                coalesce(player_state_id, nextval('actors_id_seq')) as state,
                coalesce(player_pawn_id, nextval('actors_id_seq')) as pawn
            from acc left join player_state on player_state.account_id = acc.id
        ),
        actors_insert as (
            INSERT INTO actors("id", "owner_account_id")
            select unnest(array[controller, pawn, state]), acc.id from actor_ids, acc
            ON CONFLICT DO NOTHING
            returning id
        ),
        insert_actor_audit_log as (
            insert into actor_audit("id", "class")
                select
                    unnest(array[controller, pawn, state]) as id,
                    unnest(array['Controller', 'Pawn', 'State']) as clas
                from actor_ids
                on conflict do nothing
        ),
		demo as (
            UPDATE demo_users
                SET demo_state = CASE
                    WHEN demo_playtime_seconds IS NOT NULL THEN 'Demo'::DemoState
                    ELSE demo_state
                END
                WHERE fls_id = in_user_id
                RETURNING fls_id, demo_playtime_seconds, demo_state
		),
    	player_state_insert as (
            INSERT INTO encrypted_player_state(
            	"account_id", "encrypted_character_name", "online_status",
            	"player_controller_id", "player_pawn_id", "player_state_id",
				"return_dimension_index", "home_dimension_index", "last_login_time"
        	)
            select
                id, case
                    when in_character_name is not null then encrypt_user_data(in_character_name)
                    when encrypted_player_state.encrypted_character_name is null then encrypt_user_data('<TEMP>')
                    else encrypted_player_state.encrypted_character_name
                end,
                'Online', controller, pawn, state, in_return_dimension_index, in_home_dimension_index, now()
            from acc left join encrypted_player_state on acc.id = encrypted_player_state.account_id, actor_ids
            ON CONFLICT ("account_id")
            DO UPDATE SET
                online_status = 'Online',
                "return_dimension_index" = coalesce(in_return_dimension_index, encrypted_player_state.return_dimension_index),
                "home_dimension_index" = coalesce(in_home_dimension_index, encrypted_player_state.home_dimension_index),
                "last_login_time" = now()
            RETURNING
                account_id,
                "return_dimension_index",
                "home_dimension_index"
        ),
        inserted_count_dummy as (
            select count(*) from actors_insert
        ),
        player_actors as (
            select array_agg(full_actors.*) as actors
            from
                -- We need to refer 'returning' from inserts to ensure order of with statements
                inserted_count_dummy,
                actor_ids,
                load_full_actors(array[actor_ids.controller, actor_ids.state, actor_ids.pawn]) as full_actors
        ),
        pawn_info as (
            select id, (map, partition_id, dimension_index)::ServerInfo as server_info
            from actor_ids join actors on actors.id=actor_ids.pawn
        ),
        respawn_locations as (
            SELECT acc.id as account_id, get_respawn_locations(acc.id) as locations
            FROM acc
        ),
        this_player_tags as (
            select
                acc.id as account_id,
                array_agg(tag) as tags
            from acc join player_tags as tgs on tgs.account_id=acc.id
            group by acc.id
        ),
        keystones as (
            select player_id, array_agg(keystone_id) as purchased_keystones
            from purchased_specialization_keystones
            group by player_id
        ),
        tracks as (
            select player_id, array_agg(track_info) as progression_tracks
            from (
                select player_id, (track_type, xp_amount, level)::SpecializationTrackInfo as track_info
                from specialization_tracks
            )
            group by player_id
        ),
        journey_nodes as (
            SELECT acc.id as account_id, get_login_journey_nodes(acc.id) as journey_nodes_data
            FROM acc
        ),
        journey_nodes_cooldown as (
            SELECT acc.id as account_id, get_login_journey_nodes_cooldown(acc.id) as journey_nodes_cooldown_data
            FROM acc
        )
        select
            acc.id,
            player_actors.actors[1], player_actors.actors[2], player_actors.actors[3],
            coalesce(pawn_info.server_info, (null, null, null)::ServerInfo),
            (
                coalesce(respawn_locations.locations, array[]::RespawnLocation[]),
                player_state.pending_respawn_location_id
            )::RespawnInfo,
            coalesce(player_state.life_state, 'Alive'),
            coalesce(this_player_tags.tags, array[]::Text[]),
            player_state_insert.return_dimension_index,
            player_state.death_location,
            player_state_insert.home_dimension_index,
            demo.demo_state,
            demo.demo_playtime_seconds,
            (progression_tracks, purchased_keystones, refund_id)::SpecializationInfo,
            (
                coalesce(journey_nodes.journey_nodes_data, array[]::JourneyNodeInfo[]),
                coalesce(journey_nodes_cooldown.journey_nodes_cooldown_data, array[]::JourneyNodeCooldownInfo[]),
                coalesce(journey_tracked_cards.tracked_journey_card, ''),
                coalesce(journey_tracked_cards.tracked_landsraad_card, '')
            )::JourneyInfo,
            (player_state.last_returning_player_event_time AT TIME ZONE 'UTC')::TIMESTAMP,
            (player_state.last_returning_player_awarded_time AT TIME ZONE 'UTC')::TIMESTAMP
        from
            acc left join player_state on player_state.account_id = acc.id
                left join respawn_locations on respawn_locations.account_id = acc.id
                left join this_player_tags on this_player_tags.account_id = acc.id
                left join player_state_insert on player_state_insert.account_id = acc.id
                left join demo on demo.fls_id = acc.user
                left join journey_nodes on journey_nodes.account_id = acc.id
                left join journey_nodes_cooldown on journey_nodes_cooldown.account_id = acc.id
                left join journey_tracked_cards on journey_tracked_cards.player_id = player_state.player_controller_id
                left join keystones on keystones.player_id = player_state.player_controller_id
                left join tracks on tracks.player_id = player_state.player_controller_id
                left join specialization_refund_id on specialization_refund_id.player_id = player_state.player_controller_id,

            player_actors left join pawn_info on (player_actors.actors[3].id = pawn_info.id)
        limit 1;
END
$function$
