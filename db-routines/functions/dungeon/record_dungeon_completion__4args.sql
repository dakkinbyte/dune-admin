-- record_dungeon_completion(in_dungeon_id text, in_difficulty integer, in_duration_ms integer, players_ids bigint[]) -> void
-- oid: 58503  kind: FUNCTION  category: dungeon

CREATE OR REPLACE FUNCTION dune.record_dungeon_completion(in_dungeon_id text, in_difficulty integer, in_duration_ms integer, players_ids bigint[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	new_completion_id BIGINT;
begin
	INSERT INTO dungeon_completion VALUES (DEFAULT, in_dungeon_id, in_difficulty, in_duration_ms, array_length(players_ids, 1)) 
		RETURNING completion_id INTO new_completion_id; 
    INSERT INTO dungeon_completion_players SELECT t.player_id, new_completion_id FROM UNNEST(players_ids) AS t(player_id);
end
$function$
