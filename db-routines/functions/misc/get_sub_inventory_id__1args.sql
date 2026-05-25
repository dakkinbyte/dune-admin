-- get_sub_inventory_id(in_owner_item_id bigint) -> bigint
-- oid: 58356  kind: FUNCTION  category: misc

CREATE OR REPLACE FUNCTION dune.get_sub_inventory_id(in_owner_item_id bigint)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	inv_id BIGINT;
BEGIN
	SELECT INTO inv_id id FROM inventories WHERE item_id = in_owner_item_id;
	IF inv_id IS NULL THEN
		INSERT INTO inventories("id", "item_id") VALUES(DEFAULT, in_owner_item_id) RETURNING id INTO inv_id;
	END IF;
	RETURN inv_id;
END $function$
