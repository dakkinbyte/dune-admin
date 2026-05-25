-- verify_item_dup_backup_tool(in_account_id bigint, in_vehicle_id bigint, in_cheat_type dune.cheat_type_enum) -> void
-- oid: 58649  kind: FUNCTION  category: inventory

CREATE OR REPLACE FUNCTION dune.verify_item_dup_backup_tool(in_account_id bigint, in_vehicle_id bigint, in_cheat_type dune.cheat_type_enum)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_FLS_id TEXT;
BEGIN
	PERFORM 1 FROM inventories inv JOIN items it ON it.inventory_id = inv.id WHERE inv.actor_id = in_vehicle_id;
 	IF FOUND THEN

		-- Delete all items in this vehicle's inventories (excluding module inventories)
        PERFORM delete_items(
            (
                SELECT array_agg(i.id)
                FROM items i
                JOIN inventories inv ON inv.id = i.inventory_id
                WHERE inv.actor_id = in_vehicle_id
                AND inv.inventory_type = 0   -- 0 = vehicle backpack
            )
        );

        -- Debug logging
    	SELECT acc."user"
		    INTO v_FLS_id
		    FROM accounts acc
		    WHERE acc.id = in_account_id
		    LIMIT 1;
        RAISE WARNING 'Trying to vbt vehicle that has not an empty inventory. Behavior: % Vehicle: %, Account: %, FLS: %', in_cheat_type, in_vehicle_id, in_account_id, v_FLS_id;

        -- DB tracking
        PERFORM log_cheating(v_FLS_id, in_cheat_type);

    END IF;
END;
$function$
