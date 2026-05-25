-- landsraad_update_factions(IN in_faction_names text[]) -> void
-- oid: 58435  kind: PROCEDURE  category: landsraad

CREATE OR REPLACE PROCEDURE dune.landsraad_update_factions(IN in_faction_names text[])
 LANGUAGE plpgsql
AS $procedure$
BEGIN
	WITH new_factions AS (
        SELECT f FROM UNNEST(in_faction_names) f LEFT JOIN factions ON f = factions.name WHERE id IS NULL
    )
	INSERT INTO factions (name) SELECT * FROM new_factions;
END $procedure$
