-- save_login_target_dimension(in_fls_id text, in_login_target_dimension_index integer) -> void
-- oid: 58550  kind: FUNCTION  category: misc

CREATE OR REPLACE FUNCTION dune.save_login_target_dimension(in_fls_id text, in_login_target_dimension_index integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	INSERT INTO player_travel_state (fls_id, login_target_dimension_index)
	VALUES (in_fls_id, in_login_target_dimension_index)
	ON CONFLICT (fls_id) DO UPDATE
	SET login_target_dimension_index = EXCLUDED.login_target_dimension_index;
END;
$function$
