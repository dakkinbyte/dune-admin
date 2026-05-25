-- disband_party(in_party_id bigint) -> void
-- oid: 58238  kind: FUNCTION  category: party

CREATE OR REPLACE FUNCTION dune.disband_party(in_party_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	invite_ids BIGINT[];
	sender_ids BIGINT[];
	player_ids BIGINT[];
BEGIN
	PERFORM parties_get_exclusive_operation_lock();

	DELETE FROM party_members WHERE party_id = in_party_id;
	DELETE FROM parties WHERE party_id = in_party_id;
	DELETE FROM platform_parties_mapping WHERE dune_party_id = in_party_id;

	WITH removed_invites AS (
		DELETE FROM party_invites
		WHERE party_id = in_party_id
		RETURNING *
	) SELECT array_agg(invite_id), array_agg(sender_player_id), array_agg(player_id) from removed_invites INTO invite_ids, sender_ids, player_ids;

	PERFORM pg_notify('party_notify_channel', format('disband_party#{"PartyId" : %s, "InviteIds" : [%s] ,  "SenderIds" : [%s] , "PlayerIds" : [%s]}',
		in_party_id, ARRAY_TO_STRING(invite_ids, ','), ARRAY_TO_STRING(sender_ids, ','), ARRAY_TO_STRING(player_ids, ',')));
END
$function$
