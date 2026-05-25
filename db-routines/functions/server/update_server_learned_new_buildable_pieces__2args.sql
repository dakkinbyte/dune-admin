-- update_server_learned_new_buildable_pieces(in_account_id bigint, in_new_buildable_pieces text[]) -> void
-- oid: 58637  kind: FUNCTION  category: server

CREATE OR REPLACE FUNCTION dune.update_server_learned_new_buildable_pieces(in_account_id bigint, in_new_buildable_pieces text[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO building_progression(account_id, new_buildable_pieces) 
    VALUES(in_account_id, in_new_buildable_pieces) 
    ON CONFLICT(account_id) DO UPDATE SET new_buildable_pieces = in_new_buildable_pieces WHERE building_progression.account_id = in_account_id;
END; $function$
