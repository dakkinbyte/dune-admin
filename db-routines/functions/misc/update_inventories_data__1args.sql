-- update_inventories_data(in_inventory_data_list dune.inventorydata[]) -> void
-- oid: 58622  kind: FUNCTION  category: misc

CREATE OR REPLACE FUNCTION dune.update_inventories_data(in_inventory_data_list dune.inventorydata[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	UPDATE inventories
    SET inventory_type = (u).inventory_type, max_item_count = (u).max_item_count, max_item_volume = (u).max_item_volume
        FROM (SELECT inventory_id, inventory_type, max_item_count, max_item_volume FROM UNNEST(in_inventory_data_list)) u
    WHERE id = (u).inventory_id;
END
$function$
