-- update_removed_items_and_recipes(items_removed text[], recipes_removed text[]) -> void
-- oid: 58630  kind: FUNCTION  category: items_purge

CREATE OR REPLACE FUNCTION dune.update_removed_items_and_recipes(items_removed text[], recipes_removed text[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
    insert into removed_items (name) select unnest(items_removed);
    insert into removed_recipes (name) select unnest(recipes_removed);
end;
$function$
