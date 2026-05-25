-- delete_actor_states_travel(in_actor_id bigint) -> void
-- oid: 58199  kind: FUNCTION  category: actors

CREATE OR REPLACE FUNCTION dune.delete_actor_states_travel(in_actor_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	WITH
		traveling_actor_ids AS (
			SELECT t.id FROM get_traveling_non_player_actor_ids(in_actor_id) AS t
		)
	DELETE FROM actor_state WHERE (actor_id IN (SELECT t.id FROM traveling_actor_ids AS t(id)) OR actor_id = in_actor_id) AND state = 'Travel';
END;
$function$
