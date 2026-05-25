-- get_consumed_lore_pickups(in_actor_id bigint, in_use_temporary boolean) -> SETOF bit
-- oid: 58294  kind: FUNCTION  category: misc

CREATE OR REPLACE FUNCTION dune.get_consumed_lore_pickups(in_actor_id bigint, in_use_temporary boolean)
 RETURNS SETOF bit
 LANGUAGE plpgsql
AS $function$
BEGIN
	IF in_use_temporary THEN
		RETURN query
			SELECT consumed_bit_array
			FROM consumed_temporary_per_player_lore
			WHERE actor_id = in_actor_id;
	ELSE
		RETURN query
			SELECT consumed_bit_array
			FROM consumed_per_player_lore
			WHERE actor_id = in_actor_id;
	END IF;
END
$function$
