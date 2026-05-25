-- delete_all_dungeon_completions_by_player(in_dungeon_id text, in_player_id bigint, in_keep_completion_for_other_players boolean) -> void
-- oid: 58203  kind: FUNCTION  category: dungeon

CREATE OR REPLACE FUNCTION dune.delete_all_dungeon_completions_by_player(in_dungeon_id text, in_player_id bigint, in_keep_completion_for_other_players boolean)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
	DELETE FROM dungeon_completion WHERE
		NOT in_keep_completion_for_other_players AND
		dungeon_id = in_dungeon_id AND 
		completion_id IN (SELECT completion_id FROM dungeon_completion_players WHERE player_id = in_player_id);

	DELETE FROM dungeon_completion_players
	WHERE
		in_keep_completion_for_other_players AND
		player_id = in_player_id AND
		completion_id IN (SELECT completion_id FROM dungeon_completion WHERE dungeon_id = in_dungeon_id);
end
$function$
