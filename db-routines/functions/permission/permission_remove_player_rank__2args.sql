-- permission_remove_player_rank(in_actor_id bigint, in_player_id bigint) -> void
-- oid: 58490  kind: FUNCTION  category: permission

CREATE OR REPLACE FUNCTION dune.permission_remove_player_rank(in_actor_id bigint, in_player_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM permission_actor_rank WHERE permission_actor_id = in_actor_id AND player_id = in_player_id;

	-- Remove from player_markers using player id and, actor id as hash id
	DELETE FROM player_markers WHERE player_id = in_player_id AND marker_hash_id = in_actor_id;

	PERFORM pg_notify('permission_notify_channel', format('remove_rank#{"ActorId" : %s , "PlayerId" : %s}', in_actor_id, in_player_id));
END
$function$
