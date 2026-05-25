-- get_player_faction(in_player_id bigint, in_neutral_faction_id smallint) -> smallint
-- oid: 58333  kind: FUNCTION  category: faction

CREATE OR REPLACE FUNCTION dune.get_player_faction(in_player_id bigint, in_neutral_faction_id smallint)
 RETURNS smallint
 LANGUAGE plpgsql
AS $function$
DECLARE 
	player_faction_id SMALLINT;
BEGIN
	SELECT player_faction.faction_id INTO player_faction_id
	FROM player_faction
	WHERE actor_id = in_player_id;

	IF player_faction_id IS NULL THEN
		player_faction_id := in_neutral_faction_id;
	END IF;

	RETURN player_faction_id;
END;
$function$
