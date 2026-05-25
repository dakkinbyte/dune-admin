-- promote_new_party_leader(in_party_id bigint) -> void
-- oid: 58499  kind: FUNCTION  category: party

CREATE OR REPLACE FUNCTION dune.promote_new_party_leader(in_party_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	out_current_leader BIGINT;
	out_new_leader BIGINT;
BEGIN
	PERFORM parties_get_exclusive_operation_lock();

	-- get current leader
	SELECT party_leader_id FROM parties where party_id = in_party_id into out_current_leader;
	IF out_current_leader IS NULL THEN
		RAISE EXCEPTION 'Promoting a player to a non existing party %.', in_party_id;
	END IF;

	-- get first member in the party that is online and is not the party leader
	SELECT party_members.player_id INTO out_new_leader FROM party_members
	JOIN player_state ON player_state.player_controller_id = party_members.player_id
	WHERE party_members.party_id = in_party_id
	AND party_members.player_id <> out_current_leader
	AND player_state.online_status = 'Online';

	IF out_new_leader IS NOT NULL THEN
		-- promote
		UPDATE parties SET party_leader_id = out_new_leader WHERE party_id = in_party_id;
		PERFORM pg_notify('party_notify_channel', format('promote_party_leader#{"PartyId" : %s, "PlayerId" : %s}', in_party_id, out_new_leader));
	END IF;

END
$function$
