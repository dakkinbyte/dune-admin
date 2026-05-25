-- register_new_factions(factions text[]) -> TABLE(faction_id smallint, faction_name text)
-- oid: 58508  kind: FUNCTION  category: faction

CREATE OR REPLACE FUNCTION dune.register_new_factions(factions text[])
 RETURNS TABLE(faction_id smallint, faction_name text)
 LANGUAGE plpgsql
AS $function$
DECLARE
	found_role_id SMALLINT;
BEGIN
     -- Lock the factions table to prevent concurrent modifications. This is only done once on server start up.
    LOCK TABLE factions IN SHARE ROW EXCLUSIVE MODE;
    WITH new_factions AS (
        SELECT f FROM UNNEST(factions) f LEFT JOIN factions ON f = factions.name WHERE id IS NULL
    )
	INSERT INTO factions (name) SELECT * FROM new_factions ON CONFLICT DO NOTHING;
	RETURN QUERY SELECT * from factions;
END
$function$
