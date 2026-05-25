-- update_server_learned_building_sets(in_account_id bigint, in_learned_building_sets text[]) -> void
-- oid: 58636  kind: FUNCTION  category: building_blueprint

CREATE OR REPLACE FUNCTION dune.update_server_learned_building_sets(in_account_id bigint, in_learned_building_sets text[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO building_progression(account_id, learned_building_sets) 
    VALUES(in_account_id, in_learned_building_sets) 
    ON CONFLICT(account_id) DO UPDATE SET learned_building_sets = in_learned_building_sets WHERE building_progression.account_id = in_account_id;
END; $function$
