-- _add_item_delete_log(in_item_id bigint, in_inventory_id bigint, in_template_id text) -> void
-- oid: 58085  kind: FUNCTION  category: player_persistence

CREATE OR REPLACE FUNCTION dune._add_item_delete_log(in_item_id bigint, in_inventory_id bigint, in_template_id text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    PERFORM _add_item_trace_log('delete_item', in_item_id, in_inventory_id, in_template_id);
END;
$function$
