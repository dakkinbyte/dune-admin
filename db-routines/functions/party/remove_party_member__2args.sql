-- remove_party_member(in_player_id bigint, in_remove_reason smallint) -> void
-- oid: 58524  kind: FUNCTION  category: party

CREATE OR REPLACE FUNCTION dune.remove_party_member(in_player_id bigint, in_remove_reason smallint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	out_party_id BIGINT;
	out_player_platform_name TEXT;
	member_count BIGINT;
	out_platform_members_count BIGINT;
	removed_player_id BIGINT;
	removed_is_leader BOOLEAN;
BEGIN
	PERFORM parties_get_exclusive_operation_lock();

	DELETE FROM party_members WHERE player_id = in_player_id RETURNING player_id, party_id INTO removed_player_id, out_party_id;

	IF removed_player_id IS NOT NULL THEN
		-- check if there are more than 1 player in the party
		SELECT INTO member_count COUNT(*) FROM party_members WHERE party_id = out_party_id;
		IF member_count > 1 THEN
			-- check if removed player is leader
			SELECT INTO removed_is_leader EXISTS (SELECT 1 FROM parties WHERE party_leader_id = removed_player_id);
			IF removed_is_leader THEN
				-- TODO promote player other player
				PERFORM promote_new_party_leader(out_party_id);
			END IF;
		END IF;

		SELECT accounts.platform_name INTO out_player_platform_name FROM accounts 
		JOIN actors ON actors.id = in_player_id
		WHERE accounts.id = actors.owner_account_id;

		SELECT num_of_players INTO out_platform_members_count FROM platform_parties_mapping WHERE platform_name = out_player_platform_name AND dune_party_id = out_party_id;
		IF out_platform_members_count IS NOT NULL THEN
			-- there was a platform session for the player's party
			IF out_platform_members_count <= 1 THEN
				-- if player leaving causes no players to be in that platform session anymore, remove entry
				DELETE FROM platform_parties_mapping WHERE platform_name = out_player_platform_name AND dune_party_id = out_party_id;
			ELSE
				-- still players, decrease platform player count
				UPDATE platform_parties_mapping SET num_of_players = out_platform_members_count-1 WHERE platform_name = out_player_platform_name AND dune_party_id = out_party_id;
			END IF;
		END IF;

		PERFORM pg_notify('party_notify_channel', format(
			'remove_party_member#{"PlayerId" : %s, "PartyId" : %s, "PlayerPlatformName" : "%s", "PartyRemoveReason" : %s}', 
			removed_player_id, out_party_id, out_player_platform_name, in_remove_reason));

		If member_count <= 1 THEN
			PERFORM disband_party(out_party_id);
		END IF;

	END IF;
END
$function$
