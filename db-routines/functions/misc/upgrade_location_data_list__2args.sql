-- upgrade_location_data_list(in_location_data_list jsonb, in_map_field_name text) -> jsonb
-- oid: 58644  kind: FUNCTION  category: misc

CREATE OR REPLACE FUNCTION dune.upgrade_location_data_list(in_location_data_list jsonb, in_map_field_name text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
BEGIN
	return COALESCE(
		(
		SELECT jsonb_agg(
			CASE
				WHEN elem ? in_map_field_name
				THEN
					jsonb_set(
						elem,
						('{' || in_map_field_name ||'}')::Text[],
						upgrade_map_value(elem->in_map_field_name)
					)
				ELSE
					elem
			END
		)
		FROM jsonb_array_elements(in_location_data_list) elem
		),
		'[]'::jsonb
	);
END
$function$
