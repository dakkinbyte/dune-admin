-- load_actors(in_actor_ids bigint[], in_actor_state dune.actorstate) -> TABLE(ord bigint, actor_id bigint, generic_data dune.actorgenericdata, serial bigint)
-- oid: 58438  kind: FUNCTION  category: actors

CREATE OR REPLACE FUNCTION dune.load_actors(in_actor_ids bigint[], in_actor_state dune.actorstate DEFAULT 'Default'::dune.actorstate)
 RETURNS TABLE(ord bigint, actor_id bigint, generic_data dune.actorgenericdata, serial bigint)
 LANGUAGE plpgsql
AS $function$
begin
	return query
		with
			ids as (
				select * from unnest(in_actor_ids) with ordinality as t(id, ord)
			),
			entities as (
				select
					fgl_bridge.actor_id,
					(fgl_bridge.entity_id, fgl_bridge.slot_name, entity_data.components)::FglEntity as data
				from
					ids
					left join actor_fgl_entities as fgl_bridge on ids.id=fgl_bridge.actor_id
					left join fgl_entities as entity_data on fgl_bridge.entity_id = entity_data.entity_id
			)
		select
			ids.ord, actors.id,
			(
				coalesce(array_agg(entities.data) filter (where entities.data is not null), array[]::FglEntity[]),
				actors.properties,
				actors.gas_attributes,
				case
					when exists(select 1 from buildings where actors.id = buildings.id) then load_building(actors.id)
				end
				,
				case
					when exists(select 1 from placeables where actors.id = placeables.id) then load_placeable(actors.id)
				end
				,
				case
					when exists(select 1 from totems where actors.id = totems.id) then load_totem(actors.id)
				end
			)::ActorGenericData, actors.serial
		from
			ids
			join actors using (id)
			left join entities on actors.id = entities.actor_id
		where
        	case when (in_actor_state = 'Default') then
	        	not exists(select 1 from actor_state where actors.id = actor_state.actor_id)
    	    else
 	        	exists(select 1 from actor_state where actors.id = actor_state.actor_id and actor_state.state = in_actor_state)
    	    end
		group by ids.ord, actors.id, actors.properties, actors.gas_attributes, actors.serial
		order by ids.ord;
END
$function$
