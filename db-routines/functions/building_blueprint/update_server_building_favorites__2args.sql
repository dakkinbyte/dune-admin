-- update_server_building_favorites(in_account_id bigint, in_building_types text[]) -> void
-- oid: 58635  kind: FUNCTION  category: building_blueprint

CREATE OR REPLACE FUNCTION dune.update_server_building_favorites(in_account_id bigint, in_building_types text[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO building_favorites(account_id, building_types) 
    VALUES(in_account_id, in_building_types)
    ON CONFLICT(account_id) DO UPDATE SET building_types = in_building_types WHERE building_favorites.account_id = in_account_id;
END; $function$
