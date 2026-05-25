-- guild_handle_actor_delete(in_player_id bigint) -> void
-- oid: 58366  kind: FUNCTION  category: guild

CREATE OR REPLACE FUNCTION dune.guild_handle_actor_delete(in_player_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	out_guild_id BIGINT;
	out_new_leader_id BIGINT;
	out_guild_count INT;
BEGIN
	PERFORM guilds_get_exclusive_operation_lock();

	-- remove invites
	PERFORM reject_guild_invite(invite_id) FROM guild_invites
	where player_id = in_player_id OR sender_player_id = in_player_id;

	-- Get member guild id
	SELECT guild_id INTO out_guild_id FROM guild_members WHERE player_id = in_player_id;
	IF FOUND THEN

		SELECT INTO out_guild_count COUNT(*) FROM guild_members WHERE guild_id = out_guild_id;

		IF out_guild_count < 2 THEN
			PERFORM disband_guild(out_guild_id);
		ELSE
			-- Promote new leder
			IF is_player_guild_admin(in_player_id, out_guild_id) THEN
				SELECT player_id into out_new_leader_id from guild_members
				WHERE guild_id = out_guild_id AND player_id <> in_player_id
				LIMIT 1;
				IF out_new_leader_id IS NOT NULL THEN
					PERFORM promote_guild_member(out_guild_id, out_new_leader_id, 100::smallint);
				END IF;
			END IF;
			-- remove member
			PERFORM remove_guild_members(ARRAY[in_player_id], out_guild_id, 0::smallint);
		END IF;
	END IF;

END
$function$
