-- add_actor_audit(in_id bigint, in_class text) -> void
-- oid: 58118  kind: FUNCTION  category: anticheat

CREATE OR REPLACE FUNCTION dune.add_actor_audit(in_id bigint, in_class text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	INSERT INTO actor_audit("id", "class") VALUES(in_id, in_class) ON CONFLICT(id) DO NOTHING;
END
$function$
