-- delete_building_blueprint(in_building_item_id bigint) -> void
-- oid: 58209  kind: FUNCTION  category: building_blueprint

CREATE OR REPLACE FUNCTION dune.delete_building_blueprint(in_building_item_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    DELETE FROM building_blueprints WHERE id = in_building_item_id;
END
$function$
