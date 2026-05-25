-- permission_actor_register(in_entry dune.actorpermissionentry, in_owner_rank dune.actorpermissionrankdata) -> void
-- oid: 58487  kind: FUNCTION  category: permission

CREATE OR REPLACE FUNCTION dune.permission_actor_register(in_entry dune.actorpermissionentry, in_owner_rank dune.actorpermissionrankdata)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	INSERT INTO
		permission_actor("actor_id", "actor_name", "actor_type", "access_level", "is_child")
		VALUES(in_entry.actor_id, in_entry.actor_name, in_entry.actor_type, in_entry.access_level, in_entry.is_child);

	IF NOT in_entry.is_child THEN
		INSERT INTO permission_actor_rank("permission_actor_id", "player_id", "rank")
			VALUES(in_entry.actor_id, in_owner_rank.player_id, in_owner_rank.rank);
	END IF;

    -- there is no pg_notify here as the use cases where it may be needed are very low and we do not want to pay that cost. If we find any scenario where we need it, it can be added
END
$function$
