-- load_placeable(in_placeable_id bigint) -> dune.placeablesavedata
-- oid: 58460  kind: FUNCTION  category: building_blueprint

CREATE OR REPLACE FUNCTION dune.load_placeable(in_placeable_id bigint)
 RETURNS dune.placeablesavedata
 LANGUAGE plpgsql
AS $function$
DECLARE
	result PlaceableSaveData;
BEGIN
	SELECT
		owner_entity_id as in_owner_entity_id,
		health as in_health,
		building_type as in_building_type,
		has_hit_ground as in_has_hit_ground,
		has_buildable_support as in_has_buildable_support,
		is_hologram as in_is_hologram
	INTO result
	FROM placeables
	WHERE id = in_placeable_id;
	return result;
END
$function$
