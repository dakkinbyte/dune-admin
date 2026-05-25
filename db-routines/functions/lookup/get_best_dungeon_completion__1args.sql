-- get_best_dungeon_completion(in_dungeon_id text) -> TABLE(out_difficulty integer, out_duration_ms integer, out_players_names text[])
-- oid: 58287  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_best_dungeon_completion(in_dungeon_id text)
 RETURNS TABLE(out_difficulty integer, out_duration_ms integer, out_players_names text[])
 LANGUAGE plpgsql
AS $function$
begin
	RETURN QUERY SELECT
		d.difficulty,
		d.duration_ms,
		COALESCE((SELECT array_agg(COALESCE(ps.character_name, ''))
			FROM player_state as ps
			FULL JOIN dungeon_completion_players as dcp ON dcp.player_id = ps.player_controller_id
			WHERE dcp.completion_id = d.completion_id), ARRAY[]::TEXT[])
		FROM dungeon_completion as d
		WHERE d.dungeon_id = in_dungeon_id
		ORDER BY d.difficulty DESC, d.players_num ASC, d.duration_ms ASC, d.completion_id ASC
		LIMIT 1;
end
$function$
