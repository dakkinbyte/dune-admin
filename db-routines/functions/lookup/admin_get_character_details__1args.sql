-- admin_get_character_details(in_account_id bigint) -> TABLE(account_id bigint, player_id text, character_name text, online_status text, last_avatar_activity timestamp with time zone, class text, map text, transform dune.transform, server_id text, partition_id bigint, partition_label text, dimension_index integer, gas_attributes jsonb, properties jsonb, slot_name text, fgl_data text)
-- oid: 58130  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.admin_get_character_details(in_account_id bigint)
 RETURNS TABLE(account_id bigint, player_id text, character_name text, online_status text, last_avatar_activity timestamp with time zone, class text, map text, transform dune.transform, server_id text, partition_id bigint, partition_label text, dimension_index integer, gas_attributes jsonb, properties jsonb, slot_name text, fgl_data text)
 LANGUAGE plpgsql
AS $function$
begin
	return query SELECT player_state.account_id, accounts.user As player_id, player_state.character_name, CASE WHEN is_player_offline(accounts.user) THEN 'Offline' ELSE 'Online' END AS online_status, player_state.last_avatar_activity,
		actors.class, actors.map, actors.transform, player_state.server_id, actors.partition_id, world_partition.label, actors.dimension_index,
		actors.gas_attributes, actors.properties, actor_fgl_entities.slot_name,
		string_agg(cast(to_json((select d from (select fgl_entities.components) d)) as varchar), ', ') as fgl_data
	from fgl_entities
	left join actor_fgl_entities on fgl_entities.entity_id = actor_fgl_entities.entity_id
	left join actors on actor_fgl_entities.actor_id = actors.id
	left join player_state on player_state.player_pawn_id = actors.id
	left join accounts on accounts.id = player_state.account_id
	left join world_partition on world_partition.partition_id = actors.partition_id
	where player_state.account_id = in_account_id
		and actor_fgl_entities.slot_name = 'DuneCharacter'
	group by player_state.account_id, player_state.character_name, player_state.last_avatar_activity, accounts.user,
		actors.class, actors.map, actors.transform, player_state.server_id, actors.partition_id, world_partition.label, actors.dimension_index,
		actors.gas_attributes, actors.properties, actor_fgl_entities.slot_name;
end
$function$
