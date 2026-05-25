-- get_all_player_in_guild_online_state(in_guild_id bigint) -> SETOF dune.playeronlinestateentry
-- oid: 58281  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_all_player_in_guild_online_state(in_guild_id bigint)
 RETURNS SETOF dune.playeronlinestateentry
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY SELECT actors.id, player_state.character_name, (actors.map, actors.partition_id, actors.dimension_index)::ServerInfo, (player_state.last_avatar_activity AT TIME ZONE 'UTC')::TIMESTAMP, player_state.online_status
	FROM actors
	JOIN player_state ON player_state.player_controller_id = actors.id
    JOIN guild_members ON guild_members.player_id = actors.id
	WHERE guild_members.guild_id = in_guild_id;
END
$function$
