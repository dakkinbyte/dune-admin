-- reject_guild_invite(in_invite_id bigint) -> void
-- oid: 58514  kind: FUNCTION  category: guild

CREATE OR REPLACE FUNCTION dune.reject_guild_invite(in_invite_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	player_id BIGINT := 0;
	guild_id BIGINT := 0;
BEGIN
	PERFORM guilds_get_exclusive_operation_lock();

	-- check if invite exists
	SELECT guild_invites.player_id, guild_invites.guild_id FROM guild_invites WHERE invite_id = in_invite_id INTO player_id, guild_id;
	IF NOT FOUND THEN
    	RAISE EXCEPTION 'Trying to remove non exiting invite %.', in_invite_id;
	END IF;

	DELETE FROM guild_invites WHERE invite_id = in_invite_id;

	PERFORM pg_notify('guild_notify_channel', format('reject_invite#{"PlayerId" : %s , "GuildId" : %s}', player_id, guild_id));
END
$function$
