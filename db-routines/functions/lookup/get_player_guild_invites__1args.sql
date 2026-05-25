-- get_player_guild_invites(in_player_id bigint) -> TABLE(invite_id bigint, guild_id bigint, guild_name text, guild_description text, sender_player_id bigint, invite_sent_timespan bigint, character_name text, sender_character_name text)
-- oid: 58335  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_player_guild_invites(in_player_id bigint)
 RETURNS TABLE(invite_id bigint, guild_id bigint, guild_name text, guild_description text, sender_player_id bigint, invite_sent_timespan bigint, character_name text, sender_character_name text)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY SELECT guild_invites.invite_id, guilds.guild_id, guilds.guild_name, guilds.guild_description, guild_invites.sender_player_id, guild_invites.invite_sent_timespan, player_state.character_name, sender_player_state.character_name AS sender_character_name
	FROM guild_invites
	JOIN guilds ON guilds.guild_id = guild_invites.guild_id
	JOIN player_state ON player_state.player_controller_id = guild_invites.player_id
	JOIN player_state AS sender_player_state ON sender_player_state.player_controller_id = guild_invites.sender_player_id
	WHERE player_id = in_player_id;
END
$function$
