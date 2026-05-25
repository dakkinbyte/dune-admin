-- landsraad_update_decrees(IN in_decrees dune.landsraaddecree[]) -> void
-- oid: 58434  kind: PROCEDURE  category: landsraad

CREATE OR REPLACE PROCEDURE dune.landsraad_update_decrees(IN in_decrees dune.landsraaddecree[])
 LANGUAGE plpgsql
AS $procedure$
BEGIN
	UPDATE landsraad_decrees SET disabled = TRUE WHERE decree_name NOT IN (
        SELECT(UNNEST(in_decrees)).decree_name
    );
	INSERT INTO landsraad_decrees (decree_name, version, disabled, weight) 
		SELECT decrees.decree_name, decrees.version, decrees.disabled, decrees.weight FROM UNNEST(in_decrees) AS decrees
		ON CONFLICT(decree_name) DO UPDATE SET version = excluded.version, disabled = excluded.disabled, weight = excluded.weight;
END $procedure$
