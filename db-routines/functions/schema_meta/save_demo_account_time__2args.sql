-- save_demo_account_time(in_fls_id text, in_demo_playtime_seconds integer) -> void
-- oid: 58545  kind: FUNCTION  category: schema_meta

CREATE OR REPLACE FUNCTION dune.save_demo_account_time(in_fls_id text, in_demo_playtime_seconds integer)
 RETURNS void
 LANGUAGE sql
AS $function$
	INSERT INTO demo_users("fls_id", "demo_playtime_seconds", "demo_state")
	VALUES (in_fls_id, in_demo_playtime_seconds, 'Demo'::DemoState)
	ON CONFLICT ("fls_id") DO UPDATE
	SET demo_playtime_seconds = EXCLUDED.demo_playtime_seconds; 
$function$
