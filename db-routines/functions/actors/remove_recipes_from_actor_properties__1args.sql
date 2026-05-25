-- remove_recipes_from_actor_properties(recipes_to_remove text[]) -> void
-- oid: 58525  kind: FUNCTION  category: actors

CREATE OR REPLACE FUNCTION dune.remove_recipes_from_actor_properties(recipes_to_remove text[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
    with actors_properties as (
        select id, properties->'CraftingRecipesLibraryActorComponent'->'m_KnownItemRecipes' as recipes
        from actors
    ),
    modified_actors_properties as (
        select id, (
            select jsonb_agg(recipe)
            from jsonb_array_elements(actors_properties.recipes) as recipe
            where not (recipe->'BaseRecipeId'->>'Name' = any(recipes_to_remove))
        ) as filtered_recipes
        from actors_properties
    )
    update actors
    set properties = jsonb_set(
        actors.properties,
        '{CraftingRecipesLibraryActorComponent,m_KnownItemRecipes}',
        coalesce(modified_actors_properties.filtered_recipes, '[]'::jsonb)
    )
    from modified_actors_properties
    where actors.id = modified_actors_properties.id;
end;
$function$
