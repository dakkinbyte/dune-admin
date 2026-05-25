-- get_best_dungeons_completions_for_player(in_player_id bigint) -> TABLE(out_dungeon_id text, out_difficulty integer, out_duration_ms integer, out_players_num smallint)
-- oid: 58288  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_best_dungeons_completions_for_player(in_player_id bigint)
 RETURNS TABLE(out_dungeon_id text, out_difficulty integer, out_duration_ms integer, out_players_num smallint)
 LANGUAGE plpgsql
AS $function$
begin
	RETURN QUERY SELECT DISTINCT ON (d.dungeon_id) d.dungeon_id, d.difficulty, d.duration_ms, d.players_num
		FROM dungeon_completion as d
			INNER JOIN dungeon_completion_players as p ON p.completion_id = d.completion_id
		WHERE p.player_id = in_player_id
		ORDER BY d.dungeon_id, d.difficulty DESC, d.players_num ASC, d.duration_ms ASC, d.completion_id ASC;
end
$function$
