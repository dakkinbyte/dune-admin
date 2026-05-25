-- landsraad_change_term_end_time(end_term_id bigint, new_end_time timestamp without time zone, in_test_term boolean) -> void
-- oid: 58400  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_change_term_end_time(end_term_id bigint, new_end_time timestamp without time zone, in_test_term boolean)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	LOCK TABLE landsraad_decree_term IN EXCLUSIVE MODE;
	UPDATE landsraad_decree_term SET test_term = in_test_term WHERE term_id = end_term_id AND test_term = false;
	UPDATE landsraad_decree_term SET end_time = new_end_time AT TIME ZONE 'UTC' WHERE term_id = end_term_id;
END $function$
