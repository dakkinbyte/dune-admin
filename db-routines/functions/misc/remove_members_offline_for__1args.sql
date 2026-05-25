-- remove_members_offline_for(in_interval_seconds integer) -> void
-- oid: 58522  kind: FUNCTION  category: misc

CREATE OR REPLACE FUNCTION dune.remove_members_offline_for(in_interval_seconds integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	PERFORM parties_get_exclusive_operation_lock();

	PERFORM remove_party_member(party_members.player_id, 0::SMALLINT) FROM party_members
	JOIN player_state ON player_state.player_controller_id = party_members.player_id
	WHERE player_state.online_status = 'Offline'
	AND CURRENT_TIMESTAMP > player_state.last_avatar_activity + INTERVAL '1 second' * in_interval_seconds;

END
$function$
