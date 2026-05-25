-- delete_all_dungeon_completions_for_all_dungeons_by_player(in_player_id bigint, in_keep_completion_for_other_players boolean) -> void
-- oid: 58204  kind: FUNCTION  category: dungeon

CREATE OR REPLACE FUNCTION dune.delete_all_dungeon_completions_for_all_dungeons_by_player(in_player_id bigint, in_keep_completion_for_other_players boolean)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
	DELETE FROM dungeon_completion WHERE
		NOT in_keep_completion_for_other_players AND
		completion_id IN (SELECT completion_id FROM dungeon_completion_players WHERE player_id = in_player_id);
		
	DELETE FROM dungeon_completion_players WHERE in_keep_completion_for_other_players AND player_id = in_player_id;
end
$function$
