-- cleanup_orphaned_entities() -> trigger
-- oid: 58173  kind: FUNCTION  category: cleanup

CREATE OR REPLACE FUNCTION dune.cleanup_orphaned_entities()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM fgl_entities WHERE fgl_entities.entity_id = OLD.entity_id;
	RETURN NULL;
END
$function$
