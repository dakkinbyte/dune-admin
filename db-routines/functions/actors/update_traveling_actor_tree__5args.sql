-- update_traveling_actor_tree(in_actor_id bigint, in_target_transform dune.transform, in_target_map text, in_target_dimension_index integer, in_target_partition_id bigint) -> TABLE(out_id bigint, out_actor_state text)
-- oid: 58641  kind: FUNCTION  category: actors

CREATE OR REPLACE FUNCTION dune.update_traveling_actor_tree(in_actor_id bigint, in_target_transform dune.transform, in_target_map text, in_target_dimension_index integer, in_target_partition_id bigint)
 RETURNS TABLE(out_id bigint, out_actor_state text)
 LANGUAGE plpgsql
AS $function$
begin
	RETURN query WITH
		traveling_actor_ids AS (
			SELECT t.id FROM get_traveling_actor_ids(in_actor_id) AS t
		),
		invalid_traveling_actor_ids AS (
			SELECT id, actor_state.state::TEXT FROM traveling_actor_ids
			INNER JOIN actor_state ON actor_state.actor_id = traveling_actor_ids.id
			WHERE actor_state.state != 'Travel'
		),
		valid_traveling_actor_ids AS (
			SELECT id FROM traveling_actor_ids
			WHERE NOT EXISTS (SELECT 1 FROM invalid_traveling_actor_ids)
		),
		insert_actor_state AS (
			INSERT INTO actor_state(actor_id, state)
			SELECT id, 'Travel' FROM valid_traveling_actor_ids
			ON CONFLICT DO NOTHING
		),
		update_actors AS (
			UPDATE actors
			SET 
				transform = in_target_transform,
				dimension_index = in_target_dimension_index,
				map = in_target_map,
				partition_id = in_target_partition_id
			FROM valid_traveling_actor_ids
			WHERE actors.id = valid_traveling_actor_ids.id
		)
	SELECT * FROM invalid_traveling_actor_ids;
end
$function$
