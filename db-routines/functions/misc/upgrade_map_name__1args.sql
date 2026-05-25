-- upgrade_map_name(in_map_name text) -> text
-- oid: 58645  kind: FUNCTION  category: misc

CREATE OR REPLACE FUNCTION dune.upgrade_map_name(in_map_name text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
BEGIN
	return
		CASE in_map_name
			WHEN 'Survival_1' THEN 'HaggaBasin'
			WHEN 'SH_HarkoVillage' THEN 'HarkoVillage'
			WHEN 'DeepDesert_1' THEN 'DeepDesert'
			WHEN 'Overmap' THEN 'Overland'
			WHEN 'SH_Arrakeen' THEN 'Arrakeen'
			WHEN 'CB_Story_Hephaestus' THEN 'WreckOfHephaestus'
			WHEN 'CB_Story_Ecolab_Carthag' THEN 'BeneathCarthag'
			WHEN 'CB_SurvivalChallenge_Station_15' THEN 'Station15'
			WHEN 'CB_Story_WaterFatManor' THEN 'WaterFat'
			WHEN 'SH_FallenLight' THEN 'FallenLight'
			WHEN 'Story_ProcesVerbal' THEN 'ProcesVerbal'
			WHEN 'DLC_Story_LostHarvest' THEN 'LostHarvest'
			WHEN 'DLC_Story_LostHarvest_EcolabA' THEN 'LostHarvest_EcolabA'
			WHEN 'DLC_Story_LostHarvest_EcolabB' THEN 'LostHarvest_EcolabB'
			WHEN 'DLC_Story_LostHarvest_ForgottenLab' THEN 'LostHarvest_ForgottenLab'
			WHEN 'Story_ArtOfKanly' THEN 'ArtOfKanly'
			WHEN 'Story_HeighlinerDungeon' THEN 'HeighlinerDungeon'
			WHEN 'CB_Dungeon_Hephaestus' THEN 'WreckOfHephaestusDungeon'
			WHEN 'CB_Dungeon_OldCarthag' THEN 'OldCarthagDungeon'
			WHEN 'CB_Story_BanditFortress01' THEN 'SandfliesFortress'
			WHEN 'CB_Overland_S_05' THEN 'ClosedOffTestingStationIsland'
			WHEN 'CB_Overland_S_06' THEN 'GroundVehicleTimeTrialIsland'
			WHEN 'CB_Overland_S_04' THEN 'ErythriteCaveIsland'
			WHEN 'CB_Overland_M_01' THEN 'RadioactiveShipwreck'
			WHEN 'CB_Overland_S_07' THEN 'TheRuinsOfTsimpo'
			WHEN 'Story_Faction_Outpost_Hark' THEN 'Story_Faction_Outpost_Hark'
			WHEN 'Story_Faction_Outpost_Atre' THEN 'Story_Faction_Outpost_Atre'
			WHEN 'CB_Ecolab_Bronze_Green_089' THEN 'RadiationDungeon'
			WHEN 'CB_Ecolab_Bronze_Green_152' THEN 'ElectricityDungeon'
			WHEN 'CB_Ecolab_Bronze_Green_195' THEN 'PoisonDungeon'
			WHEN 'CB_Ecolab_Bronze_Green_024' THEN 'DarknessDungeon'
			WHEN 'CB_Ecolab_Bronze_Green_136' THEN 'FireDungeon'
			WHEN 'CB_Story_DestroyedZanovar' THEN 'DestroyedZanovar'
			WHEN 'CB_Story_OrbitalMonitor' THEN 'OrbitalMonitor'
			WHEN 'CB_Dungeon_TheFacility' THEN 'FacilityDungeon'
			WHEN 'CB_Dungeon_ThePit' THEN 'PitDungeon'
			WHEN 'CB_Overland_S_08' THEN 'WindPass'
			ELSE in_map_name
		END;
END;
$function$
