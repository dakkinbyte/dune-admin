-- _add_item_trace_log(in_function_name dune.itemtrackingfunctiontype, in_item_id bigint, in_inventory_id bigint, in_template_id text, in_position_index bigint) -> void
-- oid: 58087  kind: FUNCTION  category: player_persistence

CREATE OR REPLACE FUNCTION dune._add_item_trace_log(in_function_name dune.itemtrackingfunctiontype, in_item_id bigint, in_inventory_id bigint, in_template_id text, in_position_index bigint DEFAULT NULL::bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    owner_account_id BIGINT;
BEGIN
    IF coalesce(current_setting('dune.item_tracking_enabled', true)::BOOLEAN, false) IS FALSE THEN
        return;
    END IF;
    
    -- get item owner's account id
    SELECT act.owner_account_id
    INTO owner_account_id
    FROM inventories inv
    JOIN actors act ON act.id = inv.actor_id
    WHERE inv.id = in_inventory_id;

    INSERT INTO item_operations_staging_table (
        function_name,
        item_id,
        account_id,
        inventory_id,
        template_id,
        event_time,
        position_index
    ) VALUES (
        in_function_name,
        in_item_id,
        owner_account_id,
        in_inventory_id,
        in_template_id,
        now(),
        in_position_index
    );
END;
$function$
