-- drain_item_tracking_data() -> TABLE(function_name dune.itemtrackingfunctiontype, item_id bigint, account_id bigint, inventory_id bigint, template_id text, event_time timestamp without time zone, position_index bigint)
-- oid: 58240  kind: FUNCTION  category: inventory

CREATE OR REPLACE FUNCTION dune.drain_item_tracking_data()
 RETURNS TABLE(function_name dune.itemtrackingfunctiontype, item_id bigint, account_id bigint, inventory_id bigint, template_id text, event_time timestamp without time zone, position_index bigint)
 LANGUAGE sql
AS $function$
    DELETE FROM item_operations_staging_table
    RETURNING
        function_name,
        item_id,
        account_id,
        inventory_id,
        template_id,
        event_time AT TIME ZONE 'UTC',
        position_index;
$function$
