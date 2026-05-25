-- load_full_actors(in_ids bigint[]) -> SETOF dune.actordescription
-- oid: 58454  kind: FUNCTION  category: actors

CREATE OR REPLACE FUNCTION dune.load_full_actors(in_ids bigint[])
 RETURNS SETOF dune.actordescription
 LANGUAGE plpgsql
AS $function$
begin
	return query
		with
			ids as (
				select * from unnest(in_ids) with ordinality as t(id, ord)
			),
			entities as (
				select
					actor_id,
					(fgl_bridge.entity_id, fgl_bridge.slot_name, entity_data.components)::FglEntity as data
				from
					ids
					left join actor_fgl_entities as fgl_bridge on ids.id=fgl_bridge.actor_id
					left join fgl_entities as entity_data using (entity_id)
			)
		select
			id, "class", "transform", (
				coalesce(array_agg(entities.data) filter (where entities.data is not null), array[]::FglEntity[]),
				actors.properties,
				actors.gas_attributes,
				case
					when exists(select 1 from buildings where ids.id = buildings.id) then load_building(id)
					else null
				end,
				case
					when exists(select 1 from placeables where ids.id = placeables.id) then load_placeable(id)
					else null
				end
				,
				case
					when exists(select 1 from totems where id = totems.id) then load_totem(id)
				end
			)::ActorGenericData, actors.serial
		from
			ids
			join actors using (id)
			left join entities on id=entities.actor_id
		group by ids.ord, id, class, "transform", actors.properties, actors.gas_attributes, actors.serial
		order by ids.ord;
end
$function$
