-- get_permission_for_player_actors(in_player_id bigint, in_min_rank smallint) -> SETOF dune.actorpermissioncombineddata
-- oid: 58329  kind: FUNCTION  category: permission

CREATE OR REPLACE FUNCTION dune.get_permission_for_player_actors(in_player_id bigint, in_min_rank smallint)
 RETURNS SETOF dune.actorpermissioncombineddata
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY
	WITH player_owned_actors AS
	(
		SELECT array_agg(permission_actor_id) AS ids
		FROM permission_actor_rank join actors on actors.id = permission_actor_rank.permission_actor_id
		WHERE permission_actor_rank.player_id = in_player_id AND permission_actor_rank.rank <= in_min_rank and actors.owner_account_id is null
	)
	SELECT permissions.* FROM player_owned_actors, get_permission_for_actors(player_owned_actors.ids) AS permissions;
END
$function$
