-- get_vehicle_module_inventory_id(in_vehicle_module_id bigint, in_vehicle_module_inventory_type integer) -> bigint
-- oid: 58365  kind: FUNCTION  category: vehicle

CREATE OR REPLACE FUNCTION dune.get_vehicle_module_inventory_id(in_vehicle_module_id bigint, in_vehicle_module_inventory_type integer)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	inv_id BIGINT;
BEGIN
	SELECT INTO inv_id inventory_id FROM vehicle_module_inventories vi JOIN inventories i ON (vi.inventory_id = i.id) WHERE i.vehicle_module_id = in_vehicle_module_id AND vi.vehicle_module_inventory_type = in_vehicle_module_inventory_type;
	IF inv_id IS NULL THEN
		INSERT INTO inventories("id", "vehicle_module_id") VALUES(DEFAULT, in_vehicle_module_id) RETURNING id INTO inv_id;
		INSERT INTO vehicle_module_inventories("inventory_id", "vehicle_module_inventory_type") VALUES(inv_id, in_vehicle_module_inventory_type);
	END IF;
	RETURN inv_id;
END $function$
