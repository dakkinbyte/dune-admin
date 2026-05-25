-- get_inventory_data(in_inventory_id bigint) -> dune.inventorydata
-- oid: 58312  kind: FUNCTION  category: inventory

CREATE OR REPLACE FUNCTION dune.get_inventory_data(in_inventory_id bigint)
 RETURNS dune.inventorydata
 LANGUAGE plpgsql
AS $function$
DECLARE
    inventory_data InventoryData;
BEGIN
	SELECT INTO
        inventory_data.inventory_id, inventory_data.inventory_type, inventory_data.max_item_count, inventory_data.max_item_volume
        id, inventory_type, max_item_count, max_item_volume
    FROM inventories
    WHERE id = in_inventory_id;

	RETURN inventory_data;
END $function$
