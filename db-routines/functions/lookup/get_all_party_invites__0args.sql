-- get_all_party_invites() -> TABLE(invite_id bigint, party_id bigint, sender_player_id bigint, sender_name text, player_id bigint, player_name text, invite_sent_timespan bigint)
-- oid: 58278  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_all_party_invites()
 RETURNS TABLE(invite_id bigint, party_id bigint, sender_player_id bigint, sender_name text, player_id bigint, player_name text, invite_sent_timespan bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY SELECT party_invites.invite_id, party_invites.party_id, party_invites.sender_player_id, sender_player_state.character_name, party_invites.player_id, player_state.character_name, party_invites.invite_sent_timespan
	FROM party_invites
	JOIN player_state ON player_state.player_controller_id = party_invites.player_id
	JOIN player_state AS sender_player_state ON sender_player_state.player_controller_id = party_invites.sender_player_id;
END
$function$
