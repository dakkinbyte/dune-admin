-- ownership_handle_actor_delete(in_player_id bigint) -> void
-- oid: 58482  kind: FUNCTION  category: actors

CREATE OR REPLACE FUNCTION dune.ownership_handle_actor_delete(in_player_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	owned_totem_ids BIGINT[];
	actors_with_permission BIGINT[];
BEGIN

	-- Get owner entity ids (totems) where in_player_id is the owner
	SELECT ARRAY_AGG(owner_entity_id) into owned_totem_ids
	FROM permission_actor_rank
	JOIN permission_actor ON actor_id = permission_actor_id
	JOIN placeables on placeables.id = permission_actor_id
	WHERE player_id = in_player_id AND rank = 1::smallint; -- 1:owner

	-- Get actors where in_player_id is the owner
	SELECT ARRAY_AGG(permission_actor_id) into actors_with_permission
	FROM permission_actor_rank WHERE player_id = in_player_id AND rank = 1::smallint; -- 1:owner

	-- Remove all permissions for those actors
	IF cardinality(actors_with_permission) > 0 THEN
		DELETE FROM permission_actor_rank WHERE permission_actor_id = ANY(actors_with_permission);
		DELETE FROM MARKERS	WHERE marker_hash_id = ANY(actors_with_permission);

		PERFORM pg_notify('permission_notify_channel', format('owner_delete#{"PlayerId" : %s}', in_player_id));
	END IF;
END
$function$
