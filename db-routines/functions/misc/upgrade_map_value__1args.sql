-- upgrade_map_value(in_value jsonb) -> jsonb
-- oid: 58646  kind: FUNCTION  category: misc

CREATE OR REPLACE FUNCTION dune.upgrade_map_value(in_value jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN 
		CASE 
			WHEN jsonb_typeof(in_value) = 'string'
			THEN
				jsonb_build_object('Name', upgrade_map_name(in_value->>0))
			ELSE 
				in_value
		END;
END;
$function$
