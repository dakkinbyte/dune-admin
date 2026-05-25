-- remove_items_and_recipes(items_to_remove text[], recipes_to_remove text[]) -> void
-- oid: 58520  kind: FUNCTION  category: items_purge

CREATE OR REPLACE FUNCTION dune.remove_items_and_recipes(items_to_remove text[], recipes_to_remove text[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
declare
    items_to_remove_filtered text[];
    recipes_to_remove_filtered text[];
begin
    lock table removed_items, removed_recipes, actors, fgl_entities, items in exclusive mode;
    
    -- get the items in items_to_remove that are not in removed_items
    items_to_remove_filtered := get_items_to_remove(items_to_remove);
    
    -- remove items from fgl entities
    perform remove_items_or_recipes_from_fgl_entities(items_to_remove_filtered);
    
    -- get the recipes in recipes_to_remove that are not in removed_recipes
    recipes_to_remove_filtered := get_recipes_to_remove(recipes_to_remove);
    
    -- removes the requests that contain items or recipes from fgl_entities.
    perform remove_items_or_recipes_from_fgl_entities(recipes_to_remove_filtered);
    
    -- delete the items
    perform remove_items(items_to_remove_filtered);

    -- remove the recipes from actors known item recipes
    perform remove_recipes_from_actor_properties(recipes_to_remove_filtered);
    
    -- insert removed items and recipes in their respective tables
    perform update_removed_items_and_recipes(items_to_remove_filtered, recipes_to_remove_filtered);
end
$function$
