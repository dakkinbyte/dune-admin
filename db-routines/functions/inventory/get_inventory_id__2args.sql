-- get_inventory_id(in_actor_id bigint, in_component_name_hash integer) -> bigint
-- oid: 58313  kind: FUNCTION  category: inventory

CREATE OR REPLACE FUNCTION dune.get_inventory_id(in_actor_id bigint, in_component_name_hash integer)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	inv_id BIGINT;
BEGIN
	SELECT INTO inv_id inventory_id FROM actor_inventories ai JOIN inventories i ON (ai.inventory_id = i.id) WHERE i.actor_id = in_actor_id AND ai.component_name_hash = in_component_name_hash;
	IF inv_id IS NULL THEN
		INSERT INTO inventories("id", "actor_id") VALUES(DEFAULT, in_actor_id) RETURNING id INTO inv_id;
		INSERT INTO actor_inventories("inventory_id", "component_name_hash") VALUES(inv_id, in_component_name_hash);
	END IF;
	RETURN inv_id;
END $function$
