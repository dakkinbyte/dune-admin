-- load_vehicle_modules(in_vehicle_id bigint) -> TABLE(module_id bigint, template_id text, stats jsonb)
-- oid: 58467  kind: FUNCTION  category: vehicle

CREATE OR REPLACE FUNCTION dune.load_vehicle_modules(in_vehicle_id bigint)
 RETURNS TABLE(module_id bigint, template_id text, stats jsonb)
 LANGUAGE plpgsql
AS $function$
begin
    return query SELECT vm.id, vm.template_id, vm.stats FROM vehicle_modules vm WHERE vehicle_id = in_vehicle_id ORDER BY id;
end
$function$
