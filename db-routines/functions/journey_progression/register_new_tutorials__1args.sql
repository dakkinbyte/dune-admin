-- register_new_tutorials(tutorials text[]) -> TABLE(tutorial_id smallint, tutorial_name text)
-- oid: 58509  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.register_new_tutorials(tutorials text[])
 RETURNS TABLE(tutorial_id smallint, tutorial_name text)
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Lock the tutorials table to prevent concurrent modifications. This is only done once on server start up.
    LOCK TABLE tutorials IN SHARE ROW EXCLUSIVE MODE;

    WITH new_tutorials AS (
        SELECT q FROM unnest(tutorials) q LEFT JOIN tutorials ON q = tutorials.name WHERE id is NULL
    )
    INSERT INTO tutorials (name) SELECT * FROM new_tutorials;

    RETURN QUERY SELECT * from tutorials;
END
$function$
