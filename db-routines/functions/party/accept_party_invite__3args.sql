-- accept_party_invite(in_invite_id bigint, in_platform_session_id text, in_max_party_member_count integer) -> dune.partyacceptinviteresult
-- oid: 58117  kind: FUNCTION  category: party

CREATE OR REPLACE FUNCTION dune.accept_party_invite(in_invite_id bigint, in_platform_session_id text, in_max_party_member_count integer)
 RETURNS dune.partyacceptinviteresult
 LANGUAGE plpgsql
AS $function$
DECLARE
	out_player_id BIGINT;
	out_sender_id BIGINT;
	out_party_id BIGINT;
	out_player_platform_name TEXT;
	out_player_platform_id TEXT;
	out_sender_platform_name TEXT;
	out_sender_platform_session_id TEXT;
	out_accept_error PartyAcceptInviteResult DEFAULT 'Success'::PartyAcceptInviteResult;
BEGIN
	PERFORM parties_get_exclusive_operation_lock();

	-- check if invite exists
	SELECT party_id, player_id, sender_player_id, sender_platform_name, sender_platform_session_id FROM party_invites 
	WHERE invite_id = in_invite_id INTO out_party_id, out_player_id, out_sender_id, out_sender_platform_name, out_sender_platform_session_id;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Trying to accept non exiting party invite %.', in_invite_id;
		out_accept_error = 'NonExistingInvite'::PartyAcceptInviteResult;
	END IF;
	
	-- query receiver platform data
	SELECT acc.platform_name, acc.platform_id INTO out_player_platform_name, out_player_platform_id
	FROM accounts acc LEFT JOIN player_state ps ON acc.id=ps.account_id
	WHERE ps.player_controller_id = out_player_id;

	IF out_party_id IS NULL THEN
		PERFORM internal_create_party(in_invite_id, out_sender_id, out_sender_platform_session_id, out_sender_platform_name, 
			out_player_id, in_platform_session_id, out_player_platform_name);
	ELSE
		out_accept_error := internal_add_party_member(in_invite_id, out_party_id, out_player_id, in_platform_session_id, out_player_platform_name, in_max_party_member_count);
	END IF;

	-- Delete any sent or reiceived invites from the player who's accepting the invitation
	DELETE FROM party_invites WHERE sender_player_id = out_player_id OR player_id = out_player_id;
	RETURN out_accept_error;
END
$function$
