-- reset_server_all_player_access_codes(in_account_id bigint) -> void
-- oid: 58531  kind: FUNCTION  category: cleanup

CREATE OR REPLACE FUNCTION dune.reset_server_all_player_access_codes(in_account_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM player_access_codes
		WHERE account_id = in_account_id
		AND is_resettable = true;
END
$function$
