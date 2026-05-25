-- _character_transfer_property_not_exported_is_expected(path text) -> boolean
-- oid: 58104  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune._character_transfer_property_not_exported_is_expected(path text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE
AS $function$
	select (path = ANY(ARRAY[
		'.properties.BP_DunePlayerCharacter_C.m_CurrentVehicleId',
		'.properties.WeaponActorComponent.m_FavoriteWeaponItemDatabaseId',
		'.properties.ContractsCoordinatorComponent.m_TrackedContractItemUid',
		'.components.FItemCraftingComponent.*.RequestsQueue.*.InstigatorActorId',
		'.stats.FSinkchartsStats.*.CreatorPlayerId',
		'.components.FItemCraftingComponent.*.RequestsQueue.*.IngredientAllocations.*.ItemAllocNodes.*.AllocatedItems.*.ItemUniqueId', -- TODO [DA-4712]: Remove once this item loss is fixed
		'.stats.FBuildingBlueprintItemStats.*.PlayerBlueprintId', -- TODO [DA-4721]: Remove once this item loss is fixed
		'.properties.BP_TransportOrnithopter_CHOAM_C.m_HarnessedVehicleId',
		'.stats.FReferenceItemStats.*.ReferenceDatabaseId', -- These often point to items that no longer exist
		'.components.FTotemLandclaimComponent.*.m_PendingStakingUnitsEntityIds.*', -- Staking units are not transferred with the base backup. This is missing a cleanup
		'.components.FTotemLandclaimComponent.*.m_PendingVerticalStakingUnitsEntityIds.*' -- Staking units are not transferred with the base backup. This is missing a cleanup
	]::text[]));
$function$
