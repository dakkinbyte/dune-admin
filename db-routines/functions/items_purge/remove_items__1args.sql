-- remove_items(items_to_remove text[]) -> void
-- oid: 58519  kind: FUNCTION  category: items_purge

CREATE OR REPLACE FUNCTION dune.remove_items(items_to_remove text[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
    PERFORM delete_items(
        (
            SELECT array_agg(id)
            FROM items
            WHERE template_id = ANY (items_to_remove)
        )
    );
end;
$function$
