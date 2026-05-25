-- update_party_platform_session(in_party_id bigint, in_platform_session_id text, in_platform_name text) -> void
-- oid: 58628  kind: FUNCTION  category: party

CREATE OR REPLACE FUNCTION dune.update_party_platform_session(in_party_id bigint, in_platform_session_id text, in_platform_name text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	IF in_platform_session_id IS NULL OR length(in_platform_session_id) = 0 THEN
        RAISE EXCEPTION 'in_platform_session_id must not be empty';
    END IF;

	IF in_platform_name IS NULL OR length(in_platform_name) = 0 THEN
        RAISE EXCEPTION 'platform_name must not be empty';
    END IF;
	
	INSERT INTO platform_parties_mapping (platform_session_id, platform_name, dune_party_id)
	VALUES (in_platform_session_id, in_platform_name, in_party_id)
	ON CONFLICT (platform_name, dune_party_id)
	DO UPDATE SET platform_session_id = EXCLUDED.platform_session_id;

	PERFORM pg_notify('party_notify_channel', format('update_party_platform_id#{"PartyId" : %s, "PlatformSessionId" : "%s", "PlatformName" : "%s"}', 
		in_party_id, in_platform_session_id, in_platform_name));
END
$function$
