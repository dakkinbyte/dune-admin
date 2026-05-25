-- delete_actors(in_ids bigint[]) -> void
-- oid: 58200  kind: FUNCTION  category: actors

CREATE OR REPLACE FUNCTION dune.delete_actors(in_ids bigint[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM actors WHERE id = ANY(in_ids);
END
$function$
