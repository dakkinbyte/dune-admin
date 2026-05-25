-- save_actors(in_server_info dune.serverinfo, in_actors dune.actordescription[], in_actor_state dune.actorstate) -> TABLE(actor_id bigint, current_saved_serial bigint, saved boolean)
-- oid: 58541  kind: FUNCTION  category: actors

CREATE OR REPLACE FUNCTION dune.save_actors(in_server_info dune.serverinfo, in_actors dune.actordescription[], in_actor_state dune.actorstate DEFAULT 'Default'::dune.actorstate)
 RETURNS TABLE(actor_id bigint, current_saved_serial bigint, saved boolean)
 LANGUAGE plpgsql
AS $function$
BEGIN
	return query with
		input_actors as (
			select * from unnest(in_actors)
		),
		valid_input_actors as (
			select input_actors.id from input_actors
			left join actor_state on input_actors.id = actor_state.actor_id
			where actor_state.state = in_actor_state or (in_actor_state = 'Default' and actor_state.actor_id is null)
		),
		serial_checks as (
			select
				input.id,
				input.serial as input_serial,
				coalesce(actors.serial, 0) as saved_serial,
				input.serial >= coalesce(actors.serial, 0) and input.id in (select id from valid_input_actors) as should_save
			from
				input_actors as input left join actors using (id)
		),
		actors_to_save as (
			select i.* from input_actors as i join serial_checks as c using (id) where c.should_save
		),
		upsert_actors as (
			insert into actors(
				"id", "class", "transform",
				"gas_attributes",
				"properties",
				"map", "partition_id", "dimension_index",
				"serial"
			)
				select
					i.id, i.class_name, i.transform,
					(i.generic_data).gas_attribute_sets_json, (i.generic_data).properties_json,
					in_server_info.map, in_server_info.partition_id, coalesce(in_server_info.dimension_index, 0),
					i.serial
				from actors_to_save as i
			on conflict (id) do update
			set
				"class" = EXCLUDED.class, "transform" = case when EXCLUDED.transform is null or (EXCLUDED.transform).location = (zero_transform()).location then actors.transform else EXCLUDED.transform end,

				"gas_attributes" = EXCLUDED.gas_attributes, "properties" = EXCLUDED.properties,

				"map" = EXCLUDED.map, "partition_id" = EXCLUDED.partition_id, "dimension_index" = EXCLUDED.dimension_index,
				"serial" = EXCLUDED.serial
			returning id
		),
		fgl_entity_data as (
			select id as actor_id, (u).entity_id, (u).slot_name, (u).components_json as components
				from (select id, unnest((generic_data).entities) as u from actors_to_save) q
		),
		missing_entities as (
			select entity_id
				from actors_to_save join actor_fgl_entities as existing on (actors_to_save.id = existing.actor_id)
				where not exists(select 1 from fgl_entity_data as updated where updated.entity_id=existing.entity_id)
		),
		delete_missing_entity_links as (
			delete from actor_fgl_entities as existing using missing_entities
				where existing.entity_id=missing_entities.entity_id
				returning existing.entity_id as deleted_entity_id
		),
		delete_missing_entities as (
			delete from fgl_entities as existing using missing_entities
				where existing.entity_id=missing_entities.entity_id
		),
		upsert_entities as (
			insert into fgl_entities("entity_id", "components")
				select entity_id, components from fgl_entity_data
				on conflict (entity_id) do update
				set components=EXCLUDED.components
			returning entity_id
		),
		upsert_entity_links as (
			insert into actor_fgl_entities("actor_id", "entity_id", "slot_name")
				select fgl_entity_data.actor_id, fgl_entity_data.entity_id, fgl_entity_data.slot_name
					from fgl_entity_data left join upsert_entities using (entity_id)
					-- HACK: this is a temporary fix until we do TECH-23063
					where not entity_id in (select deleted_entity_id from delete_missing_entity_links)
				on conflict (entity_id) do update
				set
					actor_id=EXCLUDED.actor_id,
					slot_name=EXCLUDED.slot_name
			returning actor_fgl_entities.actor_id, actor_fgl_entities.entity_id
		),
		all_actor_entities as (
			select fgl_entity_data.actor_id as id, array_agg(entity_id) as entity_ids
				from fgl_entity_data
					left join upsert_entities using (entity_id)
					left join upsert_entity_links using (entity_id)
				group by fgl_entity_data.actor_id
		),
		extra_data as (
			select
				input_actors.id,
				serial_checks.saved_serial,
				(serial_checks.should_save) as saved,
				(input_actors.generic_data).building_actor_data as building_data,
				(input_actors.generic_data).placeable_actor_data as placeable_data,
				(input_actors.generic_data).totem_actor_data as totem_data,
				coalesce(all_actor_entities.entity_ids, array[]::int[]) as entity_ids
			from
				serial_checks
				left join input_actors using(id)
				left join upsert_actors using(id) -- this is needed for dependency
				left join all_actor_entities using(id) -- this is needed for dependency only
		),
		save_extras as (
			select
				extra_data.id,
				extra_data.saved_serial,
				extra_data.saved,
				case when extra_data.saved and building_data is not null then
					save_building(id, building_data)
				end,
				case when extra_data.saved and placeable_data is not null then
					save_placeable(id, placeable_data)
				end,
				case when extra_data.saved and totem_data is not null then
					save_totem(id, totem_data)
				end,
				entity_ids
			from extra_data
		)
		select id, saved_serial, save_extras.saved from save_extras;
END
$function$
