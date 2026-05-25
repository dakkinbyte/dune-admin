-- add_party_invite(in_sender_player_id bigint, in_sender_platform_name text, in_sender_platform_session_id text, in_player_id bigint, in_max_party_member_count integer, in_invite_sent_timespan bigint) -> void
-- oid: 58128  kind: FUNCTION  category: party

CREATE OR REPLACE FUNCTION dune.add_party_invite(in_sender_player_id bigint, in_sender_platform_name text, in_sender_platform_session_id text, in_player_id bigint, in_max_party_member_count integer, in_invite_sent_timespan bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	out_already_in_party BOOLEAN;
	out_already_invited BOOLEAN;
	out_sender_existing_party_id BIGINT;
	out_sender_party_count INTEGER;
	out_invite_id BIGINT;
	out_player_name TEXT;
	out_sender_name TEXT;
BEGIN

	-- check if invited player is already invited
	SELECT INTO out_already_invited EXISTS (SELECT 1 FROM party_invites where player_id = in_player_id AND sender_player_id = in_sender_player_id);
	IF out_already_invited THEN
		RAISE EXCEPTION 'The player % already has an invite from %.', in_player_id, in_sender_player_id;
	END IF;

	-- check if the sender party is full
	SELECT party_id INTO out_sender_existing_party_id from parties where party_leader_id = in_sender_player_id;
	SELECT INTO out_sender_party_count COUNT(*) FROM party_members WHERE party_id = out_sender_existing_party_id;

	IF out_sender_existing_party_id IS NOT NULL AND out_sender_party_count >= in_max_party_member_count THEN
		RAISE EXCEPTION 'Trying to invite player % for a party id % that is full.', in_player_id, out_sender_existing_party_id;
	END IF;

	-- add invite
	INSERT INTO party_invites("player_id", "party_id", "sender_player_id", "sender_platform_name", "sender_platform_session_id", "invite_sent_timespan") 
		VALUES(in_player_id, out_sender_existing_party_id, in_sender_player_id, in_sender_platform_name, in_sender_platform_session_id, in_invite_sent_timespan) RETURNING "invite_id" INTO out_invite_id;

	SELECT player_state.character_name INTO out_player_name
		FROM player_state WHERE player_state.player_controller_id = in_player_id;

	SELECT player_state.character_name INTO out_sender_name
		FROM player_state WHERE player_state.player_controller_id = in_sender_player_id;

	PERFORM pg_notify('party_notify_channel', format(
		'add_invite#{"InviteId" : %s, "SenderId" : %s, "SenderName" : "%s", "PlayerId" : %s , "PlayerName" : "%s", "InviteSentUniverseTime" : %s}',
		out_invite_id, in_sender_player_id, out_sender_name, in_player_id, out_player_name, in_invite_sent_timespan));
END
$function$
