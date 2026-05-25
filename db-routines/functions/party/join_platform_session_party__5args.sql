-- join_platform_session_party(in_leader_platform_id text, in_player_platform_id text, in_platform_session_id text, in_platform_name text, in_max_party_member_count integer) -> dune.partyacceptinviteresult
-- oid: 58396  kind: FUNCTION  category: party

CREATE OR REPLACE FUNCTION dune.join_platform_session_party(in_leader_platform_id text, in_player_platform_id text, in_platform_session_id text, in_platform_name text, in_max_party_member_count integer)
 RETURNS dune.partyacceptinviteresult
 LANGUAGE plpgsql
AS $function$
DECLARE
    out_party_id BIGINT;
	out_accept_error PartyAcceptInviteResult DEFAULT 'Success'::PartyAcceptInviteResult;
    out_leader_id BIGINT;
    out_player_id BIGINT;
BEGIN
    IF in_platform_name IS NULL OR length(in_platform_name) = 0 THEN
        RAISE EXCEPTION 'platform_name must not be empty';
    END IF;
    IF in_platform_session_id IS NULL OR length(in_platform_session_id) = 0 THEN
        RAISE EXCEPTION 'platform_session_id must not be empty';
    END IF;

    -- Fetch party id, but do nothing with it
    SELECT dune_party_id INTO out_party_id
    FROM platform_parties_mapping
    WHERE platform_session_id = in_platform_session_id
      AND platform_name = in_platform_name
    LIMIT 1;

	out_leader_id = get_controller_id_from_platform_id(in_leader_platform_id);
	out_player_id = get_controller_id_from_platform_id(in_player_platform_id);

	IF out_party_id IS NULL THEN
		-- Using same platform name and platform session id cause they are joining through system invite, they'll always be the same platform.
		PERFORM internal_create_party(NULL, out_leader_id, in_platform_session_id, in_platform_name,
			out_player_id, in_platform_session_id, in_platform_name);
	ELSE
		out_accept_error := internal_add_party_member(NULL, out_party_id, out_player_id, in_platform_session_id, in_platform_name, in_max_party_member_count);
	END IF;

	RETURN out_accept_error;
END
$function$
