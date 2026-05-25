-- save_vehicle_modules(in_add_list dune.vehiclemodule[], in_delete_list bigint[], in_stat_update dune.itemstatupdate[]) -> SETOF bigint
-- oid: 58574  kind: FUNCTION  category: vehicle

CREATE OR REPLACE FUNCTION dune.save_vehicle_modules(in_add_list dune.vehiclemodule[], in_delete_list bigint[], in_stat_update dune.itemstatupdate[])
 RETURNS SETOF bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	module VEHICLEMODULE;
	stat ItemStatUpdate;
	new_module_id BIGINT;
	currentstat RECORD;
BEGIN
	--RAISE NOTICE 'Add vehicle modules';
	-- add vehicle modules
	FOREACH module IN ARRAY in_add_list LOOP
		INSERT INTO vehicle_modules(
			"vehicle_id", "template_id", "stats"
		) VALUES(
			(module).vehicle_id, (module).template_id, (module).stats
		) RETURNING id INTO new_module_id;
		RETURN NEXT new_module_id;
	END LOOP;

	--RAISE NOTICE 'Delete vehicle modules';
	-- delete modules
	DELETE FROM vehicle_modules WHERE id = ANY(in_delete_list);

	--RAISE NOTICE 'Add vehicle module stats';
	-- add vehicle module stats
	FOREACH stat IN ARRAY in_stat_update LOOP
		UPDATE vehicle_modules SET "stats" = vehicle_modules.stats || (stat).value WHERE "id" = (stat).item_id;
	END LOOP;

	RETURN;
END
$function$
