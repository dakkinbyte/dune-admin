-- delete_server_player_access_codes(in_account_id bigint, in_access_code integer, in_access_code_type integer) -> void
-- oid: 58229  kind: FUNCTION  category: server

CREATE OR REPLACE FUNCTION dune.delete_server_player_access_codes(in_account_id bigint, in_access_code integer, in_access_code_type integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM player_access_codes
		WHERE account_id = in_account_id
		AND access_code = in_access_code
		AND access_code_type = in_access_code_type;
END
$function$
