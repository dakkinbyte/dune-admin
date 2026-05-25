-- get_recipes_to_remove(recipes_to_remove text[]) -> text[]
-- oid: 58347  kind: FUNCTION  category: items_purge

CREATE OR REPLACE FUNCTION dune.get_recipes_to_remove(recipes_to_remove text[])
 RETURNS text[]
 LANGUAGE plpgsql
AS $function$
declare
    result text[];
begin
    select array(
        select unnest(recipes_to_remove)
        except
        select name
        from removed_recipes
    ) into result;
    return result;
end;
$function$
