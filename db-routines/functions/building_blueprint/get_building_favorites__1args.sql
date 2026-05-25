-- get_building_favorites(in_account_id bigint) -> TABLE(building_types text[])
-- oid: 58290  kind: FUNCTION  category: building_blueprint

CREATE OR REPLACE FUNCTION dune.get_building_favorites(in_account_id bigint)
 RETURNS TABLE(building_types text[])
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT building_favorites.building_types FROM building_favorites WHERE account_id = in_account_id;
END; $function$
