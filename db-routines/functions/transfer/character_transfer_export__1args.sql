-- character_transfer_export(in_fls_id text) -> jsonb
-- oid: 58160  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune.character_transfer_export(in_fls_id text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_acc_id BigInt;
    v_funcom_id Text;
	v_player_controller_id BigInt;
	v_player_pawn_id BigInt;
	v_vehicle_ids BigInt[];
BEGIN
	select out_acc_id, out_funcom_id, out_player_controller_id, out_player_pawn_id
		into v_acc_id, v_funcom_id, v_player_controller_id, v_player_pawn_id
	from _character_transfer_pre_export_validation(in_fls_id);

	perform _character_transfer_create_data_table();

	-- accounts

    insert into pg_temp.export_data("id", "kind", "data")
        select id, 'acc', _character_transfer_top_level_export('acc', to_jsonb(accounts))
			from accounts where accounts.id=v_acc_id;

	-- Vehicle and player actors

	insert into pg_temp.export_data("id", "kind", "data")
		select id, 'act', _character_transfer_top_level_export('act', to_jsonb(actors) - 'partition_id' #- '{properties,LandsraadCharacterComponent,m_NextContractAbandonUniverseTimeLimit}')
			from actors where id IN (
				-- player actors
            	select unnest(array[player_controller_id, player_state_id, player_pawn_id]) as id
					from player_state where account_id=v_acc_id
				union
				-- backup vehicles
				select vehicle_id as id from backup_vehicles where account_id=v_acc_id
				union
				-- recovered vehicles
				select vehicle_id as id from recovered_vehicles where account_id=v_acc_id
				union
				-- base backup actors
				select actor_id as id from base_backup_linked_actors where id IN (
					select id from base_backups where player_id=v_player_controller_id
				)
	        );

	insert into pg_temp.export_data("id", "kind", "data")
        select entity_id, 'fgl', _character_transfer_top_level_export(
			'fgl', to_jsonb(fgl_entities) || to_jsonb(actor_fgl_entities)
		) from actor_fgl_entities join fgl_entities using (entity_id) where actor_id IN (
			select id from pg_temp.export_data where kind='act'
		);


	-- Actor state entries tied to actors we export
	insert into pg_temp.export_data("id", "kind", "data")
	select actor_id, 'ActorState', _character_transfer_top_level_export('ActorState', to_jsonb(actor_state))
		from actor_state where
			actor_id IN (select id from pg_temp.export_data where kind = 'act');


	-- Permission data for the transferred actors
	insert into pg_temp.export_data("id", "kind", "data")
		select actor_id, 'PermissionActor', _character_transfer_top_level_export('PermissionActor', to_jsonb(permission_actor))
			from permission_actor where actor_id IN (select id from pg_temp.export_data where kind = 'act');
	insert into pg_temp.export_data("id", "kind", "data")
		select permission_actor_id, 'PermissionActorRank', _character_transfer_top_level_export('PermissionActorRank', to_jsonb(permission_actor_rank))
			from permission_actor_rank where
				permission_actor_id IN (select id from pg_temp.export_data where kind = 'act')
				and player_id IN (select id from pg_temp.export_data where kind = 'act');

	-- vehicles and vehicle modules

    insert into pg_temp.export_data("kind", "data")
        select 'Vehicle', _character_transfer_top_level_export('Vehicle', to_jsonb(vehicles))
			-- vehicle ids are aliases for actor ids
            from vehicles where id IN (select id from pg_temp.export_data where kind = 'act');

	insert into pg_temp.export_data("id", "kind", "data")
        select id, 'VehicleModule', _character_transfer_top_level_export('VehicleModule', to_jsonb(vehicle_modules))
			-- vehicle ids are aliases for actor ids
            from vehicle_modules where vehicle_id IN (select id from pg_temp.export_data where kind = 'act');

	insert into pg_temp.export_data("kind", "data")
		select 'BackupVehicle', _character_transfer_top_level_export('BackupVehicle', to_jsonb(backup_vehicles))
			from backup_vehicles where account_id=v_acc_id;

	insert into pg_temp.export_data("kind", "data")
		select 'RecoveredVehicle', _character_transfer_top_level_export('RecoveredVehicle', to_jsonb(recovered_vehicles))
			from recovered_vehicles where account_id=v_acc_id;

	-- inventories and items

    insert into pg_temp.export_data("id", "kind", "data")
        select id, 'inv', _character_transfer_top_level_export('inv', to_jsonb(inventories))
            from inventories where
				actor_id IN (select id from pg_temp.export_data where kind = 'act')
				or vehicle_module_id IN (select id from pg_temp.export_data where kind = 'VehicleModule');

    insert into pg_temp.export_data("id", "kind", "data")
        select id, 'itm', _character_transfer_top_level_export('itm', to_jsonb(items))
            from items where inventory_id IN (select id from pg_temp.export_data where kind = 'inv');

    insert into pg_temp.export_data("id", "kind", "data")
        select null, 'ActorInventory', _character_transfer_top_level_export('ActorInventory', to_jsonb(actor_inventories))
            from actor_inventories where inventory_id IN (select id from pg_temp.export_data where kind = 'inv');

	insert into pg_temp.export_data("id", "kind", "data")
        select null, 'VehicleModuleInventory',
			_character_transfer_top_level_export('VehicleModuleInventory', to_jsonb(vehicle_module_inventories))
            from vehicle_module_inventories where inventory_id IN (select id from pg_temp.export_data where kind = 'inv');

	-- Base backups (related actors are already added in the actors section)
	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'Building', _character_transfer_top_level_export('Building', to_jsonb(buildings))
			from buildings where id in (select id from pg_temp.export_data where kind = 'act');

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'BuildingInstance', _character_transfer_top_level_export('BuildingInstance', to_jsonb(building_instances))
			from building_instances where building_id in (select id from pg_temp.export_data where kind = 'act');

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'Placeable', _character_transfer_top_level_export('Placeable', to_jsonb(placeables))
			from placeables where id in (select id from pg_temp.export_data where kind = 'act');

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'Totem', _character_transfer_top_level_export('Totem', to_jsonb(totems))
			from totems where id in (select id from pg_temp.export_data where kind = 'act');

	insert into pg_temp.export_data("id", "kind", "data")
		select id, 'BaseBackup', _character_transfer_top_level_export('BaseBackup', to_jsonb(base_backups))
			from base_backups where player_id=v_player_controller_id;

	insert into pg_temp.export_data("id", "kind", "data")
		select id, 'BaseBackupLinkedActor', _character_transfer_top_level_export('BaseBackupLinkedActor', to_jsonb(base_backup_linked_actors))
			from base_backup_linked_actors where id IN (
				select id from pg_temp.export_data where kind='BaseBackup'
			);

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'LandclaimSegment', _character_transfer_top_level_export('LandclaimSegment', to_jsonb(landclaim_segments))
			from landclaim_segments where totem_id IN (
				select id from pg_temp.export_data where kind='act'
			);

	insert into pg_temp.export_data("id", "kind", "data")
		select id, 'TaxInvoice', _character_transfer_top_level_export('TaxInvoice', to_jsonb(tax_invoice))
			from tax_invoice where totem_id IN (
				select id from pg_temp.export_data where kind='act'
			);

	-- Other stuff

	insert into pg_temp.export_data("id", "kind", "data")
		select id, 'Faction', _character_transfer_top_level_export('Faction', to_jsonb(factions))
			from factions;

	insert into pg_temp.export_data("id", "kind", "data")
		select id, 'Tutorial', _character_transfer_top_level_export('Tutorial', to_jsonb(tutorials))
			from tutorials where id IN (select distinct tutorial_id from tutorial_per_player where player_id=v_player_controller_id);

	insert into pg_temp.export_data("id", "kind", "data")
		select id, 'Keystone', _character_transfer_top_level_export('Keystone', to_jsonb(specialization_keystones_map))
			from specialization_keystones_map where id IN (select distinct keystone_id from purchased_specialization_keystones where player_id=v_player_controller_id);

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'RespawnLocation',
				_character_transfer_top_level_export('RespawnLocation', to_jsonb(player_respawn_locations))
				|| jsonb_build_object('id', gen_random_uuid())
				-- TODO: add default to id and just delete it by filter
			from player_respawn_locations
			where account_id=v_acc_id and "group" = ANY('{PlayerStart,Checkpoint,CheckpointSafe}');

	insert into pg_temp.export_data("kind", "data")
        select 'Character', _character_transfer_top_level_export('Character', to_jsonb(player_state) - 'last_avatar_activity' - 'reconnect_grace_period_end' - 'previous_server_partition_id')
			from player_state where player_state.account_id=v_acc_id;

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'PlayerMarker', _character_transfer_top_level_export('PlayerMarker', to_jsonb(player_markers))
			from player_markers join markers using (marker_hash_id, dimension_index, map_name_id) join map_names using (map_name_id)
				where dimension_index=-1 and player_id=v_player_controller_id and map_name <> 'DeepDesert'
				and ((marker).payload_type <> 'EMarkerPayloadType::Default' or ((marker).payload_type = 'EMarkerPayloadType::Default' and (marker).marker_type like 'FlourSand%'));

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'Marker', _character_transfer_top_level_export('Marker', to_jsonb(markers))
			from markers join player_markers using (marker_hash_id, dimension_index, map_name_id) join map_names using (map_name_id)
				where dimension_index=-1 and player_id=v_player_controller_id and map_name <> 'DeepDesert'
				and ((marker).payload_type <> 'EMarkerPayloadType::Default' or ((marker).payload_type = 'EMarkerPayloadType::Default' and (marker).marker_type like 'FlourSand%'));

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'DialogueMetNpc', _character_transfer_top_level_export('DialogueMetNpc', to_jsonb(dialogue_met_npcs))
			from dialogue_met_npcs where player_id=v_player_controller_id;

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'DialogueTakenNode', _character_transfer_top_level_export('DialogueTakenNode', to_jsonb(dialogue_taken_nodes))
			from dialogue_taken_nodes where player_id=v_player_controller_id;

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'PlayerFaction', _character_transfer_top_level_export('PlayerFaction', to_jsonb(player_faction))
			from player_faction where actor_id=v_player_controller_id;

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'PlayerFactionReputation', _character_transfer_top_level_export('PlayerFactionReputation', to_jsonb(player_faction_reputation))
			from player_faction_reputation where actor_id=v_player_controller_id;

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'ConsumedLore', _character_transfer_top_level_export('ConsumedLore', to_jsonb(consumed_per_player_lore))
			from consumed_per_player_lore where actor_id=v_player_controller_id;

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'PlayerTutorial', _character_transfer_top_level_export('PlayerTutorial', to_jsonb(tutorial_per_player))
			from tutorial_per_player where player_id=v_player_controller_id;

    insert into pg_temp.export_data("id", "kind", "data")
		select null, 'PurchasedKeystone', _character_transfer_top_level_export('PurchasedKeystone', to_jsonb(purchased_specialization_keystones))
			from purchased_specialization_keystones where player_id=v_player_controller_id;

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'SpecializationTracks', _character_transfer_top_level_export('SpecializationTracks', to_jsonb(specialization_tracks))
			from specialization_tracks where player_id=v_player_controller_id;

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'SpecializationRefund', _character_transfer_top_level_export('SpecializationRefund', to_jsonb(specialization_refund_id))
			from specialization_refund_id where player_id=v_player_controller_id;

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'BuildingFavorite', _character_transfer_top_level_export('BuildingFavorite', to_jsonb(building_favorites))
			from building_favorites where account_id=v_acc_id;

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'BuildingProgression', _character_transfer_top_level_export('BuildingProgression', to_jsonb(building_progression))
			from building_progression where account_id=v_acc_id;

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'CommuninetPlayer', _character_transfer_top_level_export('CommuninetPlayer', to_jsonb(communinet_player))
			from communinet_player where account_id=v_acc_id;

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'CommuninetPlayerChannel', _character_transfer_top_level_export('CommuninetPlayerChannel', to_jsonb(communinet_player_channels))
			from communinet_player_channels where account_id=v_acc_id;

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'JourneyStoryNode', _character_transfer_top_level_export('JourneyStoryNode', to_jsonb(journey_story_node))
			from journey_story_node where account_id=v_acc_id;

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'MapArea', _character_transfer_top_level_export('MapArea', to_jsonb(map_areas))
			from map_areas where account_id=v_acc_id and map_name <> 'DeepDesert';

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'PlayerAccessCode', _character_transfer_top_level_export('PlayerAccessCode', to_jsonb(player_access_codes))
			from player_access_codes where account_id=v_acc_id;

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'PlayerTag', _character_transfer_top_level_export('PlayerTag', to_jsonb(player_tags))
			from player_tags where account_id=v_acc_id;

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'Sinkchart', _character_transfer_top_level_export('Sinkchart', to_jsonb(sinkcharts))
			from sinkcharts where item_id IN (select id from pg_temp.export_data where kind='itm');

	insert into pg_temp.export_data("id", "kind", "data")
		select id, 'bbp', _character_transfer_top_level_export('bbp', to_jsonb(building_blueprints))
			from building_blueprints where item_id IN (select id from pg_temp.export_data where kind='itm');

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'BuildingBlueprintInstance', _character_transfer_top_level_export('BuildingBlueprintInstance', to_jsonb(building_blueprint_instances))
			from building_blueprint_instances where building_blueprint_id IN (select id from pg_temp.export_data where kind='bbp');

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'BuildingBlueprintPlaceable', _character_transfer_top_level_export('BuildingBlueprintPlaceable', to_jsonb(building_blueprint_placeables))
			from building_blueprint_placeables where building_blueprint_id IN (select id from pg_temp.export_data where kind='bbp');

	insert into pg_temp.export_data("id", "kind", "data")
		select null, 'BuildingBlueprintPentashield', _character_transfer_top_level_export('BuildingBlueprintPentashield', to_jsonb(building_blueprint_pentashields))
			from building_blueprint_pentashields where building_blueprint_id IN (select id from pg_temp.export_data where kind='bbp');

	insert into pg_temp.export_data("id", "kind", "data")
	    select player_controller_id, 'PlayerVirtualCurrencyBalance', _character_transfer_top_level_export('PlayerVirtualCurrencyBalance', to_jsonb(player_virtual_currency_balances))
            from player_virtual_currency_balances where player_controller_id = v_player_controller_id;

    insert into pg_temp.export_data("id", "kind", "data")
	    select completion_id, 'DungeonCompletion', _character_transfer_top_level_export('DungeonCompletion', to_jsonb(dungeon_completion))
            from dungeon_completion where completion_id IN (select completion_id from dungeon_completion_players where player_id = v_player_controller_id);

	insert into pg_temp.export_data("id", "kind", "data")
	    select completion_id, 'DungeonCompletionPlayer', _character_transfer_top_level_export('DungeonCompletionPlayer', to_jsonb(dungeon_completion_players))
            from dungeon_completion_players where player_id = v_player_controller_id;

    insert into pg_temp.export_data("id","kind","data")
        select null, 'LandsraadHouseRewards', _character_transfer_top_level_export('LandsraadHouseRewards', to_jsonb(landsraad_house_rewards))
            from landsraad_house_rewards where player_id = v_player_controller_id;

    update pg_temp.export_data set data=_character_transfer_replace_local_id_with_transfer_id_in_json(data, '');

    return (select jsonb_build_object(
        '_patches_checksum', (_character_transfer_get_patches_checksum()),
        'funcom_id', (v_funcom_id),
        'player_controller_id', (v_player_controller_id),
        'entries', (_character_transfer_data_table_save())
    ));
END;
$function$
