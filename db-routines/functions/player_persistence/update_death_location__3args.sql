-- update_death_location(in_pawn dune.actordescription, in_server_info dune.serverinfo, in_life_state dune.playerlifestate) -> void
-- oid: 58619  kind: FUNCTION  category: player_persistence

CREATE OR REPLACE FUNCTION dune.update_death_location(in_pawn dune.actordescription, in_server_info dune.serverinfo, in_life_state dune.playerlifestate)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF in_life_state IS NOT NULL THEN
        UPDATE encrypted_player_state
        SET
            life_state = in_life_state,
            death_location = CASE
                WHEN in_life_state != 'Alive'::PlayerLifeState THEN ((in_pawn).transform.location, (in_server_info).map, (in_server_info).dimension_index)::DeathLocation
                ELSE null
            END
        WHERE player_pawn_id = in_pawn.id;
    END IF;
END;
$function$
