-- internal_create_party(in_invite_id bigint, in_leader_id bigint, in_leader_platform_session_id text, in_leader_platform_name text, in_member_id bigint, in_platform_session_id text, in_platform_name text) -> bigint
-- oid: 58392  kind: FUNCTION  category: party

CREATE OR REPLACE FUNCTION dune.internal_create_party(in_invite_id bigint, in_leader_id bigint, in_leader_platform_session_id text, in_leader_platform_name text, in_member_id bigint, in_platform_session_id text, in_platform_name text)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	leader_registered BOOLEAN;
	players_belong_to_party BOOLEAN;
	out_party_id BIGINT;
	out_player_name TEXT;
	out_leader_name TEXT;
BEGIN

	-- Check if the leader already exists in the parties table
	SELECT INTO leader_registered EXISTS (SELECT 1 FROM parties WHERE party_leader_id = in_leader_id);
	IF leader_registered THEN
		RAISE EXCEPTION 'Leader already has a party.';
	END IF;

	-- Check if either the leader or member already exists in the party_members table
	SELECT INTO players_belong_to_party EXISTS (SELECT 1 FROM party_members WHERE player_id = in_leader_id OR player_id = in_member_id);
	IF players_belong_to_party THEN
		RAISE EXCEPTION 'One of the players is already in a party.';
	END IF;

	-- If neither condition is met, insert the new party and members
	INSERT INTO parties ("party_leader_id") VALUES (in_leader_id) RETURNING party_id INTO out_party_id;
	INSERT INTO party_members (player_id, party_id) VALUES (in_leader_id, out_party_id), (in_member_id, out_party_id);

	-- Update all of the leaders invites to have the new party as party id
	UPDATE party_invites SET party_id = out_party_id WHERE sender_player_id = in_leader_id;

	-- Get leader name
	SELECT player_state.character_name INTO out_leader_name
		FROM player_state WHERE player_state.player_controller_id = in_leader_id;

	-- Get member name
	SELECT player_state.character_name INTO out_player_name
		FROM player_state WHERE player_state.player_controller_id = in_member_id;

	-- Handle platform sessions mapping for new party
	IF in_leader_platform_name = in_platform_name THEN
		-- If players are from the same platform and leader has session id (console), we create mapping (if their platform_name and session_id are valid)
		INSERT INTO platform_parties_mapping ("platform_session_id", "platform_name", "dune_party_id", "num_of_players")
		SELECT in_leader_platform_session_id, in_leader_platform_name, out_party_id, 2
		WHERE in_leader_platform_session_id <> '' AND in_leader_platform_name <> '';
	ELSE
		-- Create leader's platform session mapping if their platform_name and session_id are valid
		INSERT INTO platform_parties_mapping ("platform_session_id", "platform_name", "dune_party_id", "num_of_players")
		SELECT in_leader_platform_session_id, in_leader_platform_name, out_party_id, 1
		WHERE in_leader_platform_session_id <> '' AND in_leader_platform_name <> '';

		-- Create member's platform session mapping if their platform_name and session_id are valid
		INSERT INTO platform_parties_mapping ("platform_session_id", "platform_name", "dune_party_id", "num_of_players")
		SELECT in_platform_session_id, in_platform_name, out_party_id, 1
		WHERE in_platform_session_id <> '' AND in_platform_name <> '';
	END IF;

	PERFORM remove_party_invite(in_invite_id, 0::smallint); -- Silent = 0

	PERFORM pg_notify('party_notify_channel', format(
		'create_party#{"PartyId" : %s, "LeaderId" : %s, "LeaderName" : "%s", "LeaderPlatformName" : "%s", "LeaderPlatformSessionId" : "%s", "MemberId" : %s, "MemberName" : "%s", "MemberPlatformName" : "%s", "MemberPlatformSessionId" : "%s"}',
		out_party_id, in_leader_id, out_leader_name, in_leader_platform_name, in_leader_platform_session_id, in_member_id, out_player_name, in_platform_name, in_platform_session_id));

	RETURN out_party_id;

END
$function$
