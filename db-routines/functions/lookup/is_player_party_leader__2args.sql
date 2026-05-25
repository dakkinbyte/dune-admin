-- is_player_party_leader(in_player_id bigint, in_party_id bigint) -> boolean
-- oid: 58395  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.is_player_party_leader(in_player_id bigint, in_party_id bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	found_leader_id SMALLINT;
BEGIN
	SELECT party_leader_id FROM parties WHERE party_id = in_party_id INTO found_leader_id;
	IF NOT FOUND THEN
		RETURN FALSE;
	END IF;
	RETURN found_leader_id = in_player_id;
END
$function$
