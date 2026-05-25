-- delete_crafted_map(in_item_id bigint) -> void
-- oid: 58211  kind: FUNCTION  category: map_areas

CREATE OR REPLACE FUNCTION dune.delete_crafted_map(in_item_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    DELETE FROM crafted_maps WHERE item_id = in_item_id;
END
$function$
