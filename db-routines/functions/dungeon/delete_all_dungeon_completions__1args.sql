-- delete_all_dungeon_completions(in_dungeon_id text) -> void
-- oid: 58202  kind: FUNCTION  category: dungeon

CREATE OR REPLACE FUNCTION dune.delete_all_dungeon_completions(in_dungeon_id text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
	DELETE FROM dungeon_completion WHERE dungeon_id = in_dungeon_id;
end
$function$
