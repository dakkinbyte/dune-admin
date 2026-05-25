-- downgrade_map_name(in_map_name text) -> text
-- oid: 58239  kind: FUNCTION  category: misc

CREATE OR REPLACE FUNCTION dune.downgrade_map_name(in_map_name text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
BEGIN
	return
		CASE in_map_name
			WHEN 'HaggaBasin' THEN 'Survival_1'
			WHEN 'HarkoVillage' THEN 'SH_HarkoVillage'
			WHEN 'DeepDesert' THEN 'DeepDesert_1'
			WHEN 'Overland' THEN 'Overmap'
			WHEN 'Arrakeen' THEN 'SH_Arrakeen'
			WHEN 'WreckOfHephaestus' THEN 'CB_Story_Hephaestus'
			WHEN 'BeneathCarthag' THEN 'CB_Story_Ecolab_Carthag'
			WHEN 'Station15' THEN 'CB_SurvivalChallenge_Station_15'
			WHEN 'WaterFat' THEN 'CB_Story_WaterFatManor'
			WHEN 'FallenLight' THEN 'SH_FallenLight'
			WHEN 'ProcesVerbal' THEN 'Story_ProcesVerbal'
			WHEN 'LostHarvest' THEN 'DLC_Story_LostHarvest'
			WHEN 'LostHarvest_EcolabA' THEN 'DLC_Story_LostHarvest_EcolabA'
			WHEN 'LostHarvest_EcolabB' THEN 'DLC_Story_LostHarvest_EcolabB'
			WHEN 'LostHarvest_ForgottenLab' THEN 'DLC_Story_LostHarvest_ForgottenLab'
			WHEN 'ArtOfKanly' THEN 'Story_ArtOfKanly'
			WHEN 'HeighlinerDungeon' THEN 'Story_HeighlinerDungeon'
			WHEN 'WreckOfHephaestusDungeon' THEN 'CB_Dungeon_Hephaestus'
			WHEN 'OldCarthagDungeon' THEN 'CB_Dungeon_OldCarthag'
			WHEN 'SandfliesFortress' THEN 'CB_Story_BanditFortress01'
			WHEN 'ClosedOffTestingStationIsland' THEN 'CB_Overland_S_05'
			WHEN 'GroundVehicleTimeTrialIsland' THEN 'CB_Overland_S_06'
			WHEN 'ErythriteCaveIsland' THEN 'CB_Overland_S_04'
			WHEN 'RadioactiveShipwreck' THEN 'CB_Overland_M_01'
			WHEN 'TheRuinsOfTsimpo' THEN 'CB_Overland_S_07'
			WHEN 'Story_Faction_Outpost_Hark' THEN 'Story_Faction_Outpost_Hark'
			WHEN 'Story_Faction_Outpost_Atre' THEN 'Story_Faction_Outpost_Atre'
            WHEN 'RadiationDungeon' THEN 'CB_Ecolab_Bronze_Green_089'
			WHEN 'ElectricityDungeon' THEN 'CB_Ecolab_Bronze_Green_152'
			WHEN 'PoisonDungeon' THEN 'CB_Ecolab_Bronze_Green_195'
			WHEN 'DarknessDungeon' THEN 'CB_Ecolab_Bronze_Green_024'
			WHEN 'FireDungeon' THEN 'CB_Ecolab_Bronze_Green_136'
			WHEN 'DestroyedZanovar' THEN 'CB_Story_DestroyedZanovar'
			WHEN 'OrbitalMonitor' THEN 'CB_Story_OrbitalMonitor'
			WHEN 'FacilityDungeon' THEN 'CB_Dungeon_TheFacility'
			WHEN 'PitDungeon' THEN 'CB_Dungeon_ThePit'
			WHEN 'WindPass' THEN 'CB_Overland_S_08'
			ELSE in_map_name
		END;
END;
$function$
