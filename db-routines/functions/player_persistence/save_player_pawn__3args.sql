-- save_player_pawn(in_pawn dune.actordescription, in_server_info dune.serverinfo, in_life_state dune.playerlifestate) -> boolean
-- oid: 58563  kind: FUNCTION  category: player_persistence

CREATE OR REPLACE FUNCTION dune.save_player_pawn(in_pawn dune.actordescription, in_server_info dune.serverinfo, in_life_state dune.playerlifestate)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
    should_save_pawn BOOLEAN;
BEGIN
    WITH
        ids_and_serials AS (
            SELECT actors.serial >= (in_pawn).serial AS should_save
            FROM actors
            WHERE actors.id = in_pawn.id
        )
        SELECT should_save FROM ids_and_serials
        INTO should_save_pawn;

    IF NOT should_save_pawn THEN
        RETURN false;
    END IF;

    PERFORM save_actors(in_server_info, ARRAY[in_pawn]);

    PERFORM update_death_location(in_pawn, in_server_info, in_life_state);

    RETURN true;
END;
$function$
