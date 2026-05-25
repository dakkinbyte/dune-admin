-- get_player_access_codes(in_account_id bigint) -> TABLE(access_code integer, access_code_type integer)
-- oid: 58331  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_player_access_codes(in_account_id bigint)
 RETURNS TABLE(access_code integer, access_code_type integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT p.access_code, p.access_code_type
    FROM player_access_codes AS p
    WHERE p.account_id = in_account_id;
END; $function$
