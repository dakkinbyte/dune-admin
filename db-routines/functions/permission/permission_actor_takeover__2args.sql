-- permission_actor_takeover(in_entry dune.actorpermissionentry, in_owner_rank dune.actorpermissionrankdata) -> void
-- oid: 58488  kind: FUNCTION  category: permission

CREATE OR REPLACE FUNCTION dune.permission_actor_takeover(in_entry dune.actorpermissionentry, in_owner_rank dune.actorpermissionrankdata)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	found_actor_id BIGINT;
	found_guild_id BIGINT;
	found_previous_owner BIGINT;
BEGIN

	-- Check if the actor is already owned to avoid exploits
	SELECT player_id into found_previous_owner FROM permission_actor_rank WHERE permission_actor_id = in_entry.actor_id AND rank = 1::smallint;
	IF found_previous_owner IS NOT NULL THEN
		RAISE NOTICE 'Player % trying to claim ownership over actor % already owned by player %.',
			in_owner_rank.player_id, in_entry.actor_id, found_previous_owner;
		return;
	END IF;

	SELECT actor_id FROM permission_actor WHERE actor_id = in_entry.actor_id INTO found_actor_id;
	IF NOT FOUND THEN
		PERFORM permission_actor_register(in_entry, in_owner_rank);
		RETURN;
	END IF;

	SELECT guild_id FROM guild_members WHERE player_id = in_entry.actor_id INTO found_guild_id;
	IF NOT FOUND THEN
		found_guild_id := 0;
	END IF;

	DELETE FROM permission_actor_rank WHERE permission_actor_id = in_entry.actor_id;
	INSERT INTO permission_actor_rank("permission_actor_id", "player_id", "rank")
		VALUES(in_entry.actor_id, in_owner_rank.player_id, in_owner_rank.rank);

	PERFORM pg_notify('permission_notify_channel', format('takeover#{"ActorId" : %s , "PlayerId" : %s, "PlayerGuildId" : %s}', in_entry.actor_id, in_owner_rank.player_id, found_guild_id));
END
$function$
