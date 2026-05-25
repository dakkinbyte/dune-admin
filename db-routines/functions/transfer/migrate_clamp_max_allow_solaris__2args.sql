-- migrate_clamp_max_allow_solaris(in_pawn_id bigint, max_solaris_allowed bigint) -> void
-- oid: 58477  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune.migrate_clamp_max_allow_solaris(in_pawn_id bigint, max_solaris_allowed bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    with all_solaris_items as (
        SELECT row_number() over (), i.id, i.stack_size FROM  inventories inv
        JOIN items i on i.inventory_id = inv.id
        WHERE inv.actor_id = in_pawn_id AND inv.inventory_type = 0 AND i.template_id = 'SolarisCoin' -- inventory_type 0 is backpack
    ), total_solaris as (
        SELECT sum(all_solaris_items.stack_size) as total
        from all_solaris_items
    ), items_to_delete AS (
        SELECT array_agg(id) AS item_ids
        FROM all_solaris_items
        WHERE row_number > 1
    ), deleted_items AS (
        SELECT delete_items(item_ids)
        FROM items_to_delete
    )
    UPDATE items
    SET stack_size = LEAST(max_solaris_allowed, total_solaris.total)
    FROM all_solaris_items, total_solaris, deleted_items
    WHERE items.id = all_solaris_items.id AND all_solaris_items.row_number = 1;
END
$function$
