-- remove_party_invite(in_invite_id bigint, in_remove_reason smallint) -> void
-- oid: 58523  kind: FUNCTION  category: party

CREATE OR REPLACE FUNCTION dune.remove_party_invite(in_invite_id bigint, in_remove_reason smallint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	out_sender_player_id BIGINT;
	out_player_id BIGINT;
BEGIN
	-- delete invite
	IF in_invite_id IS NOT NULL THEN
		DELETE FROM party_invites WHERE invite_id = in_invite_id RETURNING player_id, sender_player_id INTO out_player_id, out_sender_player_id;
		PERFORM pg_notify('party_notify_channel', format('remove_invite#{"InviteId" : %s, "Reason" : %s, "SenderId" : %s, "PlayerId" : %s}', in_invite_id, in_remove_reason, out_sender_player_id, out_player_id));
	END IF;
END
$function$
