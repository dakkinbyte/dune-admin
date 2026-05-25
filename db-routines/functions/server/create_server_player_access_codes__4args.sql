-- create_server_player_access_codes(in_account_id bigint, in_access_code integer, in_access_code_type integer, in_is_resettable boolean) -> void
-- oid: 58185  kind: FUNCTION  category: server

CREATE OR REPLACE FUNCTION dune.create_server_player_access_codes(in_account_id bigint, in_access_code integer, in_access_code_type integer, in_is_resettable boolean)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO player_access_codes(account_id, access_code, access_code_type,is_resettable)
    VALUES(in_account_id, in_access_code, in_access_code_type, in_is_resettable);
END; $function$
