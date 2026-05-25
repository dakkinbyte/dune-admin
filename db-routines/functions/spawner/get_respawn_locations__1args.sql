-- get_respawn_locations(in_account_id bigint) -> dune.respawnlocation[]
-- oid: 58349  kind: FUNCTION  category: spawner

CREATE OR REPLACE FUNCTION dune.get_respawn_locations(in_account_id bigint)
 RETURNS dune.respawnlocation[]
 LANGUAGE plpgsql
AS $function$
DECLARE
    result RespawnLocation[];
BEGIN
    SELECT
        array_agg(
            (res.id,
             (
                 CASE
                     WHEN res.locator_transform IS NOT NULL THEN 'Transform'
                     WHEN res.locator_actor_id IS NOT NULL THEN 'PersistentActor'
                     WHEN res.locator_name IS NOT NULL THEN 'StaticLocatorName'
                 END::SpawnLocatorType,
                 res.locator_transform,
                 res.locator_actor_id,
                 res.locator_name,
                 res.locator_name_index
             )::SpawnLocatorDescriptor,
             res.map,
             res.dimension,
             res.last_used_timestamp,
             res.group
            )::RespawnLocation
        )
    INTO result
    FROM player_respawn_locations res
    WHERE res.account_id = in_account_id;

    RETURN result;
END
$function$
