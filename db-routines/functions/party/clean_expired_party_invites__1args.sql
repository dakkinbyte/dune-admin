-- clean_expired_party_invites(in_invite_expire_seconds integer) -> void
-- oid: 58165  kind: FUNCTION  category: party

CREATE OR REPLACE FUNCTION dune.clean_expired_party_invites(in_invite_expire_seconds integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	PERFORM parties_get_exclusive_operation_lock();

	PERFORM remove_party_invite(invite_id, 0::smallint) FROM party_invites
	WHERE CURRENT_TIMESTAMP > TO_TIMESTAMP(invite_sent_timespan) + INTERVAL '1 second' * in_invite_expire_seconds;
END
$function$
