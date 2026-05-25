-- character_transfer_import(in_data jsonb, in_fls_id text, in_character_name text) -> bigint
-- oid: 58163  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune.character_transfer_import(in_data jsonb, in_fls_id text, in_character_name text)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_checksum TEXT;
	v_coriolis_seed BigInt;
	v_transfer_coriolis_seed BigInt;
	v_id BigInt;
	v_kind _CharacterTransferEntryKind;
	v_new_player_controller_id BigInt;
	v_vehicle_ids BigInt[];
BEGIN
	if not (select is_player_offline(in_fls_id)) then
        raise exception 'sbRP2$ - Player must be Offline';
    end if;

    PERFORM delete_account(in_fls_id, 'incoming char transfer');

    v_checksum := (select _character_transfer_get_patches_checksum());
    IF NOT in_data->>'_patches_checksum' = v_checksum THEN
        raise exception 'sb9R2$ - Patches checksum mismatch, expected: %, got: %', v_checksum, in_data->>'_patches_checksum';
    END IF;

	perform _character_transfer_create_data_table();
	perform _character_transfer_data_table_load(in_data->'entries');

	update pg_temp.export_data set data=_character_transfer_replace_transfer_id_with_local_id_in_json(data, '');

	-- accounts

	insert into encrypted_accounts
		select (jsonb_populate_record(
			null::encrypted_accounts,
			_character_transfer_top_level_import(kind, data, id)
			|| jsonb_build_object(
				'encrypted_funcom_id', encrypt_user_data(in_data->>'funcom_id'),
				'user', in_fls_id
			)
		)).*
		from pg_temp.export_data
		where kind = 'acc';

	-- player and vehicle actors

	insert into actors
		select (jsonb_populate_record(null::actors, _character_transfer_top_level_import(kind, data, id))).*
		from pg_temp.export_data
		where kind = 'act';

	insert into fgl_entities
		select (jsonb_populate_record(null::fgl_entities, _character_transfer_top_level_import(kind, data, id))).*
		from pg_temp.export_data
		where kind = 'fgl';

	insert into actor_fgl_entities
		select (jsonb_populate_record(null::actor_fgl_entities, _character_transfer_top_level_import(kind, data, id))).*
		from pg_temp.export_data
		where kind = 'fgl';

	insert into actor_state
		select (jsonb_populate_record(null::actor_state, _character_transfer_top_level_import(kind, data, id))).*
		from pg_temp.export_data
		where kind = 'ActorState';

	insert into permission_actor
		select (jsonb_populate_record(null::permission_actor, _character_transfer_top_level_import(kind, data, id))).*
		from pg_temp.export_data
		where kind = 'PermissionActor';

	insert into permission_actor_rank
		select (jsonb_populate_record(null::permission_actor_rank, _character_transfer_top_level_import(kind, data, id))).*
		from pg_temp.export_data
		where kind = 'PermissionActorRank';


	-- vehicle and vehicle modules

	insert into vehicles
		select (jsonb_populate_record(null::vehicles, _character_transfer_top_level_import(kind, data, id))).*
		from pg_temp.export_data
		where kind = 'Vehicle';

	insert into vehicle_modules
		select (jsonb_populate_record(null::vehicle_modules, _character_transfer_top_level_import(kind, data, id))).*
		from pg_temp.export_data
		where kind = 'VehicleModule';

	-- You can VBT as co-owner, but then there will be no owner in target BG. This is a state that permission system doesn't support.
	-- So for backed up vehicles we also update the players ownership so they are now set as owner.
	WITH inserted_backup_vehicles AS (
			INSERT INTO backup_vehicles
				SELECT (jsonb_populate_record(null::backup_vehicles, _character_transfer_top_level_import(kind, data, id))).*
				FROM pg_temp.export_data
				WHERE kind = 'BackupVehicle'
			RETURNING vehicle_id
		)
		SELECT array_agg(vehicle_id) INTO v_vehicle_ids FROM inserted_backup_vehicles;
	perform _character_transfer_ensure_player_is_owner_of_vbt_vehicle(v_vehicle_ids);

	insert into recovered_vehicles
		select (jsonb_populate_record(null::recovered_vehicles, _character_transfer_top_level_import(kind, data, id))).*
		from pg_temp.export_data
		where kind = 'RecoveredVehicle';

	-- inventories and items

	insert into inventories
		select (jsonb_populate_record(null::inventories, _character_transfer_top_level_import(kind, data, id))).*
		from pg_temp.export_data e
		where kind = 'inv';

	insert into items
		select (jsonb_populate_record(null::items, _character_transfer_top_level_import(kind, data, id))).*
		from pg_temp.export_data
		where kind = 'itm';

	insert into actor_inventories
		select (jsonb_populate_record(null::actor_inventories, _character_transfer_top_level_import(kind, data, id))).*
		from pg_temp.export_data
		where kind = 'ActorInventory';

	insert into vehicle_module_inventories
		select (jsonb_populate_record(null::vehicle_module_inventories, _character_transfer_top_level_import(kind, data, id))).*
		from pg_temp.export_data
		where kind = 'VehicleModuleInventory';

	-- Base backups
	insert into buildings
		select (jsonb_populate_record(null::buildings, _character_transfer_top_level_import(kind, data, id))).*
		from pg_temp.export_data
		where kind = 'Building';

	insert into building_instances
		select (jsonb_populate_record(null::building_instances, _character_transfer_top_level_import(kind, data, id))).*
		from pg_temp.export_data
		where kind = 'BuildingInstance';

	insert into placeables
		select (jsonb_populate_record(null::placeables, _character_transfer_top_level_import(kind, data, id))).*
		from pg_temp.export_data
		where kind = 'Placeable';

	insert into totems
		select (jsonb_populate_record(null::totems, _character_transfer_top_level_import(kind, data, id))).*
		from pg_temp.export_data
		where kind = 'Totem';

	insert into base_backups
		select (jsonb_populate_record(null::base_backups, _character_transfer_top_level_import(kind, data, id))).*
		from pg_temp.export_data
		where kind = 'BaseBackup';

	insert into base_backup_linked_actors
		select (jsonb_populate_record(null::base_backup_linked_actors, _character_transfer_top_level_import(kind, data, id))).*
		from pg_temp.export_data
		where kind = 'BaseBackupLinkedActor';

	insert into landclaim_segments
		select (jsonb_populate_record(null::landclaim_segments, _character_transfer_top_level_import(kind, data, id))).*
		from pg_temp.export_data
		where kind = 'LandclaimSegment';

	insert into tax_invoice
		select (jsonb_populate_record(null::tax_invoice, _character_transfer_top_level_import(kind, data, id))).*
		from pg_temp.export_data
		where kind = 'TaxInvoice';

	-- other stuff

	insert into encrypted_player_state
		select (jsonb_populate_record(
			null::encrypted_player_state,
			_character_transfer_top_level_import(kind, data, id)
			|| jsonb_build_object(
				'encrypted_character_name', encrypt_user_data(in_character_name)
			)
		)).*
		from pg_temp.export_data
		where kind = 'Character'
		returning player_controller_id into v_new_player_controller_id;

	insert into player_respawn_locations
		select (
			jsonb_populate_record(null::player_respawn_locations, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'RespawnLocation';

	insert into markers
		select (
			jsonb_populate_record(null::markers, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'Marker'
	on conflict ("marker_hash_id", "dimension_index", "map_name_id") do nothing;

	insert into player_markers
		select (
			jsonb_populate_record(null::player_markers, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'PlayerMarker';

	insert into dialogue_met_npcs
		select (
			jsonb_populate_record(null::dialogue_met_npcs, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'DialogueMetNpc';

	insert into dialogue_taken_nodes
		select (
			jsonb_populate_record(null::dialogue_taken_nodes, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'DialogueTakenNode';

	insert into player_faction
		select (
			jsonb_populate_record(null::player_faction, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'PlayerFaction';

	insert into player_faction_reputation
		select (
			jsonb_populate_record(null::player_faction_reputation, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'PlayerFactionReputation';

	insert into consumed_per_player_lore
		select (
			jsonb_populate_record(null::consumed_per_player_lore, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'ConsumedLore';

	insert into tutorial_per_player
		select (
			jsonb_populate_record(null::tutorial_per_player, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'PlayerTutorial';

    insert into purchased_specialization_keystones
		select (
			jsonb_populate_record(null::purchased_specialization_keystones, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'PurchasedKeystone';

    insert into specialization_tracks
		select (
			jsonb_populate_record(null::specialization_tracks, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'SpecializationTracks';

    insert into specialization_refund_id
		select (
			jsonb_populate_record(null::specialization_refund_id, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'SpecializationRefund';

	insert into building_favorites
		select (
			jsonb_populate_record(null::building_favorites, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'BuildingFavorite';

	insert into building_progression
		select (
			jsonb_populate_record(null::building_progression, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'BuildingProgression';

	insert into communinet_player
		select (
			jsonb_populate_record(null::communinet_player, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'CommuninetPlayer';

	insert into communinet_player_channels
		select (
			jsonb_populate_record(null::communinet_player_channels, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'CommuninetPlayerChannel';

	insert into journey_story_node
		select (
			jsonb_populate_record(null::journey_story_node, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'JourneyStoryNode';

	insert into map_areas
		select (
			jsonb_populate_record(null::map_areas, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'MapArea';

	insert into player_access_codes
		select (
			jsonb_populate_record(null::player_access_codes, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'PlayerAccessCode';

	insert into player_tags
		select (
			jsonb_populate_record(null::player_tags, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'PlayerTag';

	insert into sinkcharts
		select (
			jsonb_populate_record(null::sinkcharts, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'Sinkchart';

	insert into building_blueprints
		select (
			jsonb_populate_record(null::building_blueprints, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'bbp';

	insert into building_blueprint_instances
		select (
			jsonb_populate_record(null::building_blueprint_instances, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'BuildingBlueprintInstance';

	insert into building_blueprint_placeables
		select (
			jsonb_populate_record(null::building_blueprint_placeables, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'BuildingBlueprintPlaceable';

	insert into building_blueprint_pentashields
		select (
			jsonb_populate_record(null::building_blueprint_pentashields, _character_transfer_top_level_import(kind, data, id))
		).*
		from pg_temp.export_data
		where kind = 'BuildingBlueprintPentashield';

	insert into player_virtual_currency_balances
        select (
            jsonb_populate_record(null::player_virtual_currency_balances, _character_transfer_top_level_import(kind, data, id))
        ).*
        from pg_temp.export_data
        where kind = 'PlayerVirtualCurrencyBalance';

	insert into dungeon_completion
        select (
            jsonb_populate_record(null::dungeon_completion, _character_transfer_top_level_import(kind, data, id))
        ).*
        from pg_temp.export_data
        where kind = 'DungeonCompletion';

	insert into dungeon_completion_players
        select (
            jsonb_populate_record(null::dungeon_completion_players, _character_transfer_top_level_import(kind, data, id))
        ).*
        from pg_temp.export_data
        where kind = 'DungeonCompletionPlayer';

    insert into landsraad_house_rewards
        select (
                   jsonb_populate_record(null::landsraad_house_rewards, _character_transfer_top_level_import(kind, data, id))
                   ).*
        from pg_temp.export_data
        where kind = 'LandsraadHouseRewards';

	PERFORM set_character_import_state(in_fls_id, 'Complete'::TransferImportState);
	return v_new_player_controller_id;
END;
$function$
