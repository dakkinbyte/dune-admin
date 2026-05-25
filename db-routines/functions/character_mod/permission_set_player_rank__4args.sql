-- permission_set_player_rank(in_actor_id bigint, in_player_id bigint, in_rank smallint, in_map_id text) -> void
-- oid: 58493  kind: FUNCTION  category: character_mod

CREATE OR REPLACE FUNCTION dune.permission_set_player_rank(in_actor_id bigint, in_player_id bigint, in_rank smallint, in_map_id text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	found_actor_id BIGINT;
	found_guild_id BIGINT;
BEGIN
	SELECT permission_actor_id FROM permission_actor_rank WHERE permission_actor_id = in_actor_id AND player_id = in_player_id INTO found_actor_id;
	IF NOT FOUND THEN
    	INSERT INTO permission_actor_rank("permission_actor_id", "player_id", "rank") VALUES(in_actor_id, in_player_id, in_rank);
    ELSE
	    UPDATE permission_actor_rank SET rank = in_rank WHERE permission_actor_rank.permission_actor_id = in_actor_id AND player_id = in_player_id;
	END IF;

	SELECT guild_id FROM guild_members WHERE player_id = in_actor_id INTO found_guild_id;
	IF NOT FOUND THEN
		found_guild_id := 0;
	END IF;

	PERFORM permission_actor_create_or_update_base_marker(in_actor_id, in_player_id, in_rank);

    PERFORM pg_notify('permission_notify_channel', format('set_rank#{"ActorId" : %s , "PlayerId" : %s, "PlayerGuildId" : %s, "Rank" : %s, "Map" : %s}', in_actor_id, in_player_id, found_guild_id, in_rank, in_map_id));
END
$function$
