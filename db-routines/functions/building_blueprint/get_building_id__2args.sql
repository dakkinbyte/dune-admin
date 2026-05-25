-- get_building_id(in_actor_id bigint, in_class text) -> dune.buildinggetidcomposite
-- oid: 58291  kind: FUNCTION  category: building_blueprint

CREATE OR REPLACE FUNCTION dune.get_building_id(in_actor_id bigint, in_class text)
 RETURNS dune.buildinggetidcomposite
 LANGUAGE plpgsql
AS $function$
BEGIN
	IF not exists(select 1 from buildings where "id" = in_actor_id) THEN
		if in_actor_id is null or in_actor_id = 0 then
			in_actor_id := (SELECT assign_actor_id(in_class));
		end if;

		INSERT INTO buildings("id") VALUES(in_actor_id);
	END IF;

    return ROW(in_actor_id)::BuildingGetIdComposite;
END
$function$
