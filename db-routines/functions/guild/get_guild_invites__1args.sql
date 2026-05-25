-- get_guild_invites(in_guild_id bigint) -> TABLE(invite_id bigint, player_id bigint, sender_player_id bigint, invite_sent_timespan bigint, character_name text, sender_character_name text)
-- oid: 58310  kind: FUNCTION  category: guild

CREATE OR REPLACE FUNCTION dune.get_guild_invites(in_guild_id bigint)
 RETURNS TABLE(invite_id bigint, player_id bigint, sender_player_id bigint, invite_sent_timespan bigint, character_name text, sender_character_name text)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY SELECT guild_invites.invite_id, guild_invites.player_id, guild_invites.sender_player_id, guild_invites.invite_sent_timespan, player_state.character_name, sender_player_state.character_name AS sender_character_name
	FROM guild_invites
	JOIN player_state ON player_state.player_controller_id = guild_invites.player_id
	JOIN player_state AS sender_player_state ON sender_player_state.player_controller_id =  guild_invites.sender_player_id
	WHERE guild_id = in_guild_id;
END
$function$
