-- get_placeable_id(in_actor_id bigint, in_class text, in_building_type text) -> dune.placeablegetidcomposite
-- oid: 58330  kind: FUNCTION  category: building_blueprint

CREATE OR REPLACE FUNCTION dune.get_placeable_id(in_actor_id bigint, in_class text, in_building_type text)
 RETURNS dune.placeablegetidcomposite
 LANGUAGE plpgsql
AS $function$
DECLARE
	placeable_id BIGINT;
BEGIN
	SELECT INTO placeable_id id FROM placeables WHERE "id" = in_actor_id;

	IF placeable_id IS NULL THEN
		SELECT assign_actor_id(in_class) id INTO placeable_id;
		INSERT INTO placeables("id", "building_type") VALUES(placeable_id, in_building_type);
	END IF;

    return ROW(placeable_id)::PlaceableGetIdComposite;
END
$function$
