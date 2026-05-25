-- internal_add_party_member(in_invite_id bigint, in_party_id bigint, in_player_id bigint, in_platform_session_id text, in_platform_name text, in_max_party_member_count integer) -> dune.partyacceptinviteresult
-- oid: 58391  kind: FUNCTION  category: party

CREATE OR REPLACE FUNCTION dune.internal_add_party_member(in_invite_id bigint, in_party_id bigint, in_player_id bigint, in_platform_session_id text, in_platform_name text, in_max_party_member_count integer)
 RETURNS dune.partyacceptinviteresult
 LANGUAGE plpgsql
AS $function$
DECLARE
	party_exists BOOLEAN;
	member_count INTEGER;
	out_platform_members_count INTEGER;
	out_player_name TEXT;
	out_accept_error PartyAcceptInviteResult DEFAULT 'Success'::PartyAcceptInviteResult;
BEGIN

	-- check if party exists
	SELECT INTO party_exists EXISTS (SELECT 1 FROM parties WHERE party_id = in_party_id);
	IF NOT party_exists THEN
		PERFORM remove_party_invite(in_invite_id, 2::smallint); -- PartyNoLongerExists = 2
		RAISE NOTICE 'Trying to add player % to non existing party %.', in_player_id, in_party_id;
		out_accept_error = 'NonExistingParty'::PartyAcceptInviteResult;
		RETURN out_accept_error;
	END IF;

	-- check party member count
	SELECT INTO member_count COUNT(*) FROM party_members WHERE party_id = in_party_id;
	IF member_count >= in_max_party_member_count THEN
		PERFORM remove_party_invite(in_invite_id, 1::smallint); -- PartyFull = 1
		RAISE NOTICE 'Trying to add more members than the allowed % to party %.', in_max_party_member_count, in_party_id;
		out_accept_error = 'PartyFull'::PartyAcceptInviteResult;
		RETURN out_accept_error;
	END IF;

	-- insert member
	INSERT INTO party_members("player_id", "party_id") VALUES(in_player_id, in_party_id);

    -- track platform information
    SELECT num_of_players INTO out_platform_members_count FROM platform_parties_mapping WHERE platform_name = in_platform_name AND dune_party_id = in_party_id;
    IF out_platform_members_count IS NOT NULL THEN
        -- there was a platform session for the player's party
		UPDATE platform_parties_mapping SET num_of_players = out_platform_members_count+1 WHERE platform_name = in_platform_name AND dune_party_id = in_party_id;
    ELSE
		-- no mapping for this platform yet, add
		INSERT INTO platform_parties_mapping ("platform_session_id", "platform_name", "dune_party_id", "num_of_players")
		SELECT in_platform_session_id, in_platform_name, in_party_id, 1
		WHERE in_platform_session_id <> '' AND in_platform_name <> '';
    END IF;

	-- Get player name
	SELECT player_state.character_name INTO out_player_name
		FROM player_state WHERE player_state.player_controller_id = in_player_id;

	PERFORM remove_party_invite(in_invite_id, 0::smallint); -- Silent = 0

	PERFORM pg_notify('party_notify_channel', format(
		'add_party_member#{"PartyId" : %s, "PlayerId" : %s, "PlayerName" : "%s", "PlayerPlatformName" : "%s", "PlayerPlatformSessionId" : "%s"}', 
		in_party_id, in_player_id, out_player_name, in_platform_name, in_platform_session_id));

	RETURN out_accept_error;
END
$function$
