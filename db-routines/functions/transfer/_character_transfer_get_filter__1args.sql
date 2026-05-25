-- _character_transfer_get_filter(kind dune._charactertransferentrykind) -> dune._charactertransferdatafilter
-- oid: 58101  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune._character_transfer_get_filter(kind dune._charactertransferentrykind)
 RETURNS dune._charactertransferdatafilter
 LANGUAGE sql
 IMMUTABLE
AS $function$
	select case
		when kind = 'acc' then _character_transfer_data_filter('id', '{user,funcom_id}')
		when kind = 'act' then _character_transfer_data_filter('id', '{}', ('owner_account_id', 'acc', false))
		when kind = 'inv' then _character_transfer_data_filter(
			'id',
			'{exchange_id,item_id}',
			('actor_id', 'act', false),
			('vehicle_module_id', 'VehicleModule', false)
		)
		when kind = 'itm' then _character_transfer_data_filter(
			'id', '{}',
			('inventory_id', 'inv', true)
		)
		when kind = 'fgl' then _character_transfer_data_filter(
			'entity_id', '{}',
			('actor_id', 'act', true)
		)
		when kind = 'bbp' then _character_transfer_data_filter(
			'id', '{}',
			('item_id', 'itm', true),
			('player_id', 'act', false)
		)

		when kind = 'Faction' then _character_transfer_data_filter('id', '{}')
		when kind = 'Tutorial' then _character_transfer_data_filter('id', '{}')
		when kind = 'Keystone' then _character_transfer_data_filter('id', '{}')

		when kind = 'Character' then _character_transfer_data_filter(
			null, '{character_name}',
			('account_id', 'acc', true),
			('player_pawn_id', 'act', true),
			('player_controller_id', 'act', true),
			('player_state_id', 'act', true)
		)
		when kind = 'RespawnLocation' then _character_transfer_data_filter(
			null, '{}',
			('account_id', 'acc', true)
		)
		when kind = 'PlayerMarker' then _character_transfer_data_filter(null, '{}', ('player_id', 'act', true))
		when kind = 'Marker' then _character_transfer_data_filter(null, '{}')
		when kind = 'DialogueMetNpc' then _character_transfer_data_filter(null, '{}', ('player_id', 'act', true))
		when kind = 'DialogueTakenNode' then _character_transfer_data_filter(null, '{}', ('player_id', 'act', true))

		when kind = 'PlayerFaction' then _character_transfer_data_filter(
			null, '{}',
			('actor_id', 'act', true), ('faction_id', 'Faction', true)
		)
		when kind = 'PlayerFactionReputation' then _character_transfer_data_filter(
			null, '{}',
			('actor_id', 'act', true), ('faction_id', 'Faction', true)
		)
		when kind = 'ConsumedLore' then _character_transfer_data_filter(null, '{}', ('actor_id', 'act', true))
		when kind = 'PlayerTutorial' then _character_transfer_data_filter(null, '{}', ('player_id', 'act', true), ('tutorial_id', 'Tutorial', true))
        when kind = 'PurchasedKeystone' then _character_transfer_data_filter(null, '{}', ('player_id', 'act', true), ('keystone_id', 'Keystone', true))
		when kind = 'SpecializationTracks' then _character_transfer_data_filter(null, '{}', ('player_id', 'act', true))
		when kind = 'SpecializationRefund' then _character_transfer_data_filter(null, '{}', ('player_id', 'act', true))

		when kind = 'BuildingFavorite' then _character_transfer_data_filter(null, '{}', ('account_id', 'acc', true))
		when kind = 'BuildingProgression' then _character_transfer_data_filter(null, '{}', ('account_id', 'acc', true))
		when kind = 'CommuninetPlayer' then _character_transfer_data_filter(null, '{}', ('account_id', 'acc', true))
		when kind = 'CommuninetPlayerChannel' then _character_transfer_data_filter(null, '{}', ('account_id', 'acc', true))
		when kind = 'JourneyStoryNode' then _character_transfer_data_filter(null, '{}', ('account_id', 'acc', true))
		when kind = 'MapArea' then _character_transfer_data_filter(null, '{}', ('account_id', 'acc', true))
		when kind = 'PlayerAccessCode' then _character_transfer_data_filter(null, '{}', ('account_id', 'acc', true))
		when kind = 'PlayerTag' then _character_transfer_data_filter(null, '{}', ('account_id', 'acc', true))

		when kind = 'ActorInventory' then _character_transfer_data_filter(null, '{}', ('inventory_id', 'inv', true))
		when kind = 'Sinkchart' then _character_transfer_data_filter(null, '{}', ('item_id', 'itm', true))

		when kind = 'BackupVehicle' then _character_transfer_data_filter(null, '{}', ('account_id', 'acc', true), ('vehicle_id', 'act', true))
		when kind = 'RecoveredVehicle' then _character_transfer_data_filter(null, '{}', ('account_id', 'acc', true), ('vehicle_id', 'act', true))
		when kind = 'Vehicle' then _character_transfer_data_filter(null, '{}', ('id', 'act', true))
		when kind = 'VehicleModule' then _character_transfer_data_filter('id', '{}', ('vehicle_id', 'act', true))
		when kind = 'VehicleModuleInventory' then _character_transfer_data_filter(null, '{}', ('inventory_id', 'inv', true))

		when kind = 'ActorState' then _character_transfer_data_filter(null, '{}', ('actor_id', 'act', true))

		when kind = 'PermissionActor' then _character_transfer_data_filter(null, '{}', ('actor_id', 'act', true))
		when kind = 'PermissionActorRank' then _character_transfer_data_filter(null, '{}', ('permission_actor_id', 'act', true), ('player_id', 'act', true))

		when kind = 'BuildingBlueprintInstance' then _character_transfer_data_filter(null, '{}', ('building_blueprint_id', 'bbp', true))
		when kind = 'BuildingBlueprintPlaceable' then _character_transfer_data_filter(null, '{}', ('building_blueprint_id', 'bbp', true))
		when kind = 'BuildingBlueprintPentashield' then _character_transfer_data_filter(null, '{}', ('building_blueprint_id', 'bbp', true))

		when kind = 'Building' then _character_transfer_data_filter(null, '{}', ('id', 'act', true))
		when kind = 'BuildingInstance' then _character_transfer_data_filter(null, '{}', ('building_id', 'act', true), ('owner_entity_id', 'fgl', false))
		when kind = 'Placeable' then _character_transfer_data_filter(null, '{}', ('id', 'act', true), ('owner_entity_id', 'fgl', false))
		when kind = 'BaseBackup' then _character_transfer_data_filter('id', '{}', ('player_id', 'act', true))
		when kind = 'BaseBackupLinkedActor' then _character_transfer_data_filter(null, '{}', ('id', 'BaseBackup', true), ('actor_id', 'act', true))
		when kind = 'LandclaimSegment' then _character_transfer_data_filter(null, '{}', ('totem_id', 'act', true))
		when kind = 'TaxInvoice' then _character_transfer_data_filter('id', '{}', ('totem_id', 'act', true))

		when kind = 'PlayerVirtualCurrencyBalance' then _character_transfer_data_filter(null, '{}', ('player_controller_id', 'act', true))

		when kind = 'DungeonCompletion' then _character_transfer_data_filter('completion_id', '{}')
		when kind = 'DungeonCompletionPlayer' then _character_transfer_data_filter(null, '{}', ('player_id', 'act', true), ('completion_id', 'DungeonCompletion', true))
		when kind = 'Totem' then _character_transfer_data_filter(null, '{}', ('id', 'act', true))

        when kind = 'LandsraadHouseRewards' then _character_transfer_data_filter(null, '{}', ('player_id', 'act', true))
	end;
$function$
