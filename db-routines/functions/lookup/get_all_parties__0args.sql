-- get_all_parties() -> TABLE(party_id bigint, player_id bigint, player_name text, party_leader_id bigint, platform_session_id text, platform_name text, platform_players_count integer)
-- oid: 58277  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_all_parties()
 RETURNS TABLE(party_id bigint, player_id bigint, player_name text, party_leader_id bigint, platform_session_id text, platform_name text, platform_players_count integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        parties.party_id,
        party_members.player_id,
        player_state.character_name,
        parties.party_leader_id,
        platform_parties_mapping.platform_session_id,
        platform_parties_mapping.platform_name,
        platform_parties_mapping.num_of_players
    FROM party_members
    JOIN parties ON party_members.party_id = parties.party_id
    JOIN player_state ON player_state.player_controller_id = party_members.player_id
    LEFT JOIN platform_parties_mapping ON platform_parties_mapping.dune_party_id = parties.party_id;
END
$function$
