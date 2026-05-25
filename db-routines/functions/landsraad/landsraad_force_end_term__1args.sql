-- landsraad_force_end_term(end_term_id bigint) -> void
-- oid: 58409  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_force_end_term(end_term_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	PERFORM landsraad_change_term_end_time(end_term_id, now() AT TIME ZONE 'UTC', false);
END $function$
