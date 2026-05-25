-- set_demo_state(in_user_id text, in_demo_state dune.demostate) -> void
-- oid: 58592  kind: FUNCTION  category: schema_meta

CREATE OR REPLACE FUNCTION dune.set_demo_state(in_user_id text, in_demo_state dune.demostate)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	UPDATE demo_users
	SET demo_state = in_demo_state
	WHERE fls_id = in_user_id;
END
$function$
