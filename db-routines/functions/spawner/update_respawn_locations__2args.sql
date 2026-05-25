-- update_respawn_locations(player_id bigint, respawn_locations dune.respawnlocation[]) -> void
-- oid: 58632  kind: FUNCTION  category: spawner

CREATE OR REPLACE FUNCTION dune.update_respawn_locations(player_id bigint, respawn_locations dune.respawnlocation[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    PERFORM 1
    FROM unnest(respawn_locations) AS loc
        WHERE
        (loc.locator).type != 'Invalid' AND NOT (
            (loc.locator).type = 'Transform' AND (loc.locator).transform IS NOT NULL AND (loc.locator).actor_id IS NULL AND (loc.locator).name IS NULL
            OR
            (loc.locator).type = 'PersistentActor' AND (loc.locator).actor_id IS NOT NULL AND (loc.locator).transform IS NULL AND (loc.locator).name IS NULL
            OR
            (loc.locator).type = 'StaticLocatorName' AND (loc.locator).name IS NOT NULL AND (loc.locator).transform IS NULL AND (loc.locator).actor_id IS NULL
        );

    IF FOUND THEN
        RAISE EXCEPTION 'Invalid respawn location in input array. Check locator type and associated fields.';
    END IF;

    WITH
    updated_respawn_locations AS (
        SELECT
            id,
            "group",
            (locator).transform AS locator_transform,
            (locator).actor_id AS locator_actor_id,
            (locator).name AS locator_name,
            (locator).name_index AS locator_name_index,
            map,
            dimension,
            last_used_timestamp
        FROM unnest(respawn_locations) AS updated
    ),
    delete_missing_respawn_locations AS (
        DELETE FROM player_respawn_locations AS existing
        WHERE NOT EXISTS (
            SELECT 1 FROM updated_respawn_locations AS updated WHERE updated.id = existing.id
        )
        AND existing.account_id = player_id
    )
    INSERT INTO player_respawn_locations(
        "id", "account_id", "group", "locator_transform", "locator_actor_id", "locator_name", "locator_name_index", "map", "dimension", "last_used_timestamp"
    )
    SELECT
        up.id, player_id, up.group, up.locator_transform, up.locator_actor_id, up.locator_name, up.locator_name_index, up.map, up.dimension, up.last_used_timestamp
    FROM updated_respawn_locations AS up
    WHERE up.locator_actor_id IS NULL OR EXISTS (
        SELECT 1 FROM actors WHERE id = up.locator_actor_id
    )
    ON CONFLICT ("id", "account_id")
    DO UPDATE SET
        "account_id" = EXCLUDED.account_id,
        "group" = EXCLUDED.group,
        "locator_transform" = EXCLUDED.locator_transform,
        "locator_actor_id" = EXCLUDED.locator_actor_id,
        "locator_name" = EXCLUDED.locator_name,
        "locator_name_index" = EXCLUDED.locator_name_index,
        "map" = EXCLUDED.map,
        "dimension" = EXCLUDED.dimension,
        "last_used_timestamp" = EXCLUDED.last_used_timestamp;
END;
$function$
