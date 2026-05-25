-- get_learned_new_buildable_pieces(in_account_id bigint) -> SETOF text
-- oid: 58317  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.get_learned_new_buildable_pieces(in_account_id bigint)
 RETURNS SETOF text
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT UNNEST(new_buildable_pieces) FROM building_progression WHERE account_id = in_account_id;
END; $function$
