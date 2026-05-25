-- base_backup_recycle(in_base_backup_id bigint, in_target_inventory_id bigint) -> integer
-- oid: 58151  kind: FUNCTION  category: base_backup

CREATE OR REPLACE FUNCTION dune.base_backup_recycle(in_base_backup_id bigint, in_target_inventory_id bigint)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    base_backup_items_moved INT;
BEGIN
    UPDATE items
    SET inventory_id = in_target_inventory_id
    FROM
        inventories inv
        JOIN base_backup_linked_actors bbla ON inv.actor_id = bbla.actor_id
    WHERE
        items.inventory_id = inv.id
        AND bbla.id = in_base_backup_id;

    get diagnostics base_backup_items_moved = ROW_COUNT;

    -- Re-organize the index of all the items
    UPDATE items
    SET position_index = new_index
    FROM (
        SELECT
            id,
            ROW_NUMBER() OVER (ORDER BY position_index) - 1 AS new_index
        FROM items
        WHERE inventory_id = in_target_inventory_id
    ) AS sub
    WHERE items.id = sub.id;

    PERFORM base_backup_delete(in_base_backup_id);

    return base_backup_items_moved;
END
$function$
