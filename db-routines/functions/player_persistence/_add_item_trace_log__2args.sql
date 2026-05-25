-- _add_item_trace_log(in_function_name dune.itemtrackingfunctiontype, in_item_locations dune.inventoryitemlocation[]) -> void
-- oid: 58086  kind: FUNCTION  category: player_persistence

CREATE OR REPLACE FUNCTION dune._add_item_trace_log(in_function_name dune.itemtrackingfunctiontype, in_item_locations dune.inventoryitemlocation[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF coalesce(current_setting('dune.item_tracking_enabled', true)::BOOLEAN, false) IS FALSE THEN
        return;
    END IF;
    
    INSERT INTO item_operations_staging_table (
        function_name,
        item_id,
        account_id,
        inventory_id,
        template_id,
        event_time,
        position_index
    )
    SELECT
        in_function_name,
        (loc).item_id,
        act.owner_account_id,
        (loc).inventory_id,
        NULL, -- template_id
        now(),
        (loc).position_index
    FROM UNNEST(in_item_locations) AS loc
    JOIN inventories inv ON inv.id = (loc).inventory_id
    JOIN actors act ON act.id = inv.actor_id;
END;
$function$
