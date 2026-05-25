-- change_player_faction(in_player_id bigint, in_faction_id smallint, neutral_faction_id smallint, in_utc_time_faction_change timestamp without time zone) -> void
-- oid: 58157  kind: FUNCTION  category: faction

CREATE OR REPLACE FUNCTION dune.change_player_faction(in_player_id bigint, in_faction_id smallint, neutral_faction_id smallint, in_utc_time_faction_change timestamp without time zone)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	found_role_id SMALLINT;
BEGIN

	if in_faction_id = neutral_faction_id THEN
		DELETE FROM player_faction WHERE actor_id = in_player_id;

		PERFORM pg_notify('faction_notify_channel', format('remove_player#{"PlayerId" : %s}', in_player_id));
	ELSE
		INSERT INTO player_faction(actor_id, faction_id, utc_time_faction_change) VALUES(in_player_id, in_faction_id, in_utc_time_faction_change) 
			ON CONFLICT (actor_id) DO UPDATE SET faction_id = in_faction_id, utc_time_faction_change = in_utc_time_faction_change;

		PERFORM pg_notify('faction_notify_channel', format('add_player#{"PlayerId" : %s, "FactionId" : %s}', in_player_id, in_faction_id));
	END IF;

	PERFORM handle_player_faction_guild_effects(in_player_id, in_faction_id, neutral_faction_id);
END
$function$
