-- get_learned_building_sets(in_account_id bigint) -> SETOF text
-- oid: 58316  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_learned_building_sets(in_account_id bigint)
 RETURNS SETOF text
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT UNNEST(learned_building_sets) FROM building_progression WHERE account_id = in_account_id;
END; $function$
