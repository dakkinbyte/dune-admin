-- set_item_tracking_enabled(in_enabled boolean) -> void
-- oid: 58593  kind: FUNCTION  category: inventory

CREATE OR REPLACE FUNCTION dune.set_item_tracking_enabled(in_enabled boolean)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    PERFORM set_config('dune.item_tracking_enabled', in_enabled::TEXT, false);
END;
$function$
