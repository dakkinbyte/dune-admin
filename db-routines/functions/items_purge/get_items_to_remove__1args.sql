-- get_items_to_remove(items_to_remove text[]) -> text[]
-- oid: 58314  kind: FUNCTION  category: items_purge

CREATE OR REPLACE FUNCTION dune.get_items_to_remove(items_to_remove text[])
 RETURNS text[]
 LANGUAGE plpgsql
AS $function$
declare
    result text[];
begin
    select array(
        select unnest(items_to_remove)
        except
        select name
        from removed_items
    ) into result;
    return result;
end;
$function$
