-- landsraad_load_player_contributions(in_term_id bigint, in_player_ids bigint[]) -> TABLE(player_id bigint, board_index smallint, amount integer)
-- oid: 58424  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_load_player_contributions(in_term_id bigint, in_player_ids bigint[])
 RETURNS TABLE(player_id bigint, board_index smallint, amount integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN query (
		SELECT contributions.player_id, tasks.board_index, FLOOR(SUM(contributions.amount))::INTEGER FROM landsraad_task_player_contributions AS contributions
			INNER JOIN landsraad_tasks AS tasks ON contributions.task_id = tasks.id
			WHERE tasks.term_id = in_term_id AND contributions.player_id = ANY(in_player_ids)
			GROUP BY contributions.player_id, tasks.board_index
	);
END $function$
