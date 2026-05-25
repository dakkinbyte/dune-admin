-- load_totem(in_id bigint) -> dune.totemsavedata
-- oid: 58464  kind: FUNCTION  category: building_blueprint

CREATE OR REPLACE FUNCTION dune.load_totem(in_id bigint)
 RETURNS dune.totemsavedata
 LANGUAGE plpgsql
AS $function$
DECLARE
	result TotemSaveData;
BEGIN
	SELECT
		landclaim_vertical_level,
		last_backup_timestamp,
		landclaim_original_global_location,
		landclaim_original_global_yaw_rotation
	INTO result
	FROM totems
	WHERE id = in_id;
	return result;
END
$function$
