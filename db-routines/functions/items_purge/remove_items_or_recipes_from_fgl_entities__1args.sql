-- remove_items_or_recipes_from_fgl_entities(item_or_recipes text[]) -> void
-- oid: 58521  kind: FUNCTION  category: items_purge

CREATE OR REPLACE FUNCTION dune.remove_items_or_recipes_from_fgl_entities(item_or_recipes text[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$ 
declare
   item_or_recipe text;
   ent_id bigint;
   components_data jsonb;
   components_data_updated jsonb;
   request jsonb;
   item_or_recipe_found boolean;
   updated_requests jsonb;
   ingredient_allocation jsonb;
   item_alloc_node jsonb;
   allocated_item jsonb;
   allocated_ingredient_info record;
begin
   drop table if exists allocated_ingredients_info_temp;
   create temp table allocated_ingredients_info_temp (item_unique_id bigint, amount bigint);
   if array_length(item_or_recipes, 1) is null then
      return;
   end if;
   foreach item_or_recipe in array(item_or_recipes)
   loop
      for ent_id, components_data in select entity_id, components
                                    from fgl_entities
                                    where components->'FItemCraftingComponent' is not null
      loop
         components_data_updated := components_data;
         if jsonb_array_length(components_data_updated->'FItemCraftingComponent'->1->'RequestsQueue') < 1 then
            return;
         end if;
         loop
            item_or_recipe_found := false;
            for request in select value::jsonb
                            from jsonb_array_elements(components_data_updated->'FItemCraftingComponent'->1->'RequestsQueue')
            loop
               if (request->'RecipeId'->>'Name' = item_or_recipe or
                  exists (select 1 from jsonb_array_elements(request->'ResultItems') where value->'ItemTemplateId'->>'Name' = item_or_recipe) or
                  exists (select 1 from jsonb_array_elements(request->'IngredientAllocations') where value->'ItemAllocNodes'->0->'ItemTemplateId'->>'Name' = item_or_recipe)) then
                  insert into allocated_ingredients_info_temp (item_unique_id, amount)
                    select (item->>'ItemUniqueId')::BigInt, (item->>'ItemAmount')::BigInt from (
                        select jsonb_array_elements(node->'AllocatedItems') as item, node as outer_node from (
                            select jsonb_array_elements(allocation->'ItemAllocNodes') as node from (
                                select jsonb_array_elements(request->'IngredientAllocations') as allocation
                            ) allocations
                        ) nodes
                    ) items;
                  updated_requests := (select jsonb_agg(value) from jsonb_array_elements(components_data_updated->'FItemCraftingComponent'->1->'RequestsQueue') where value::jsonb != request);
                  if updated_requests is null then
                     components_data_updated := jsonb_set(components_data_updated, '{FItemCraftingComponent,1,RequestsQueue}', '[]'::jsonb);
                     components_data_updated := jsonb_set(components_data_updated, '{FItemCraftingComponent,1,State}', '"Idle"'::jsonb);
                     components_data_updated := jsonb_set(components_data_updated, '{FItemCraftingComponent,1,TotalTimeToCraftInSec}', '0'::jsonb);
                     components_data_updated := jsonb_set(components_data_updated, '{FItemCraftingComponent,1,PreviouslyCompletedTimeToCraftInSec}', '0'::jsonb);
                  else
                     components_data_updated := jsonb_set(components_data_updated, '{FItemCraftingComponent,1,RequestsQueue}', updated_requests);
                  end if;
                  item_or_recipe_found := true;
                  exit;
               end if;
            end loop;
            exit when not item_or_recipe_found;
         end loop;
         update fgl_entities
         set components = components_data_updated
         where entity_id = ent_id;
      end loop;
   end loop;
   
   for allocated_ingredient_info in select * from allocated_ingredients_info_temp
   loop
      perform delete_inventory_item(allocated_ingredient_info.item_unique_id, allocated_ingredient_info.amount);
   end loop;
   
   drop table allocated_ingredients_info_temp;
end;
$function$
