-- get_permission_for_actors(in_actor_id bigint[]) -> SETOF dune.actorpermissioncombineddata
-- oid: 58328  kind: FUNCTION  category: permission

CREATE OR REPLACE FUNCTION dune.get_permission_for_actors(in_actor_id bigint[])
 RETURNS SETOF dune.actorpermissioncombineddata
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY
		SELECT
			-- ActorPermissionData
            ROW(
                ROW(
                    permission_actor.actor_id,
                    permission_actor.actor_name,
                    actors.class,
                    permission_actor.actor_type,
                    permission_actor.access_level,
                    permission_actor.is_child
                )::ActorPermissionEntry,
                array_agg(
                    ROW(
                        permission_actor_rank.rank,
                        permission_actor_rank.player_id
                    )::ActorPermissionRankData
                ) FILTER (WHERE permission_actor_rank.player_id IS NOT NULL),
                array_agg(guild_members.guild_id) FILTER (WHERE permission_actor_rank.player_id IS NOT NULL)
            )::ActorPermissionData AS data,

            -- ActorPermissionLocationData
            ROW(
                actors.id,
                actors.partition_id,
                actors.map,
                actors.dimension_index,
                actors.transform
            )::ActorPermissionLocationData AS loc
		FROM
			permission_actor
			LEFT JOIN permission_actor_rank on permission_actor.actor_id = permission_actor_rank.permission_actor_id
			LEFT JOIN guild_members ON guild_members.player_id = permission_actor_rank.player_id
			LEFT JOIN actors ON actors.id = permission_actor.actor_id
		WHERE
			permission_actor.actor_id = ANY(in_actor_id)
		GROUP BY
			permission_actor.actor_id,
			actors.id;
END
$function$
