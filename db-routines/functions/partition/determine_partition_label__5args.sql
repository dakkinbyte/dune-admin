-- determine_partition_label(in_map text, in_dimension_index integer, in_label text, in_allow_overwrite boolean, in_partition_id bigint) -> text
-- oid: 58234  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.determine_partition_label(in_map text, in_dimension_index integer, in_label text DEFAULT NULL::text, in_allow_overwrite boolean DEFAULT true, in_partition_id bigint DEFAULT NULL::bigint)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
	result_label TEXT := in_label;
	tmp_count INTEGER;
	tmp_box_max_x TEXT;
	tmp_box_max_y TEXT;
	tmp_box_min_x TEXT;
	tmp_box_min_y TEXT;
BEGIN
	-- If label is provided and we don't want to overwrite, return it
	IF result_label IS NOT NULL AND in_allow_overwrite = FALSE THEN
		RETURN result_label;
	END IF;

	CASE in_map
		WHEN 'SH_HarkoVillage' THEN return 'HarkoVillage' || '_' || in_dimension_index;
		WHEN 'SH_Arrakeen' THEN return 'Arrakeen' || '_' || in_dimension_index;
		WHEN 'SH_FallenLight' THEN return 'FallenLight' || '_' || in_dimension_index;
		WHEN 'CB_Story_Hephaestus' THEN return 'WreckOfHephaestus' || '_' || in_dimension_index;
		WHEN 'CB_Story_Ecolab_Carthag' THEN return 'BeneathCarthag' || '_' || in_dimension_index;
		WHEN 'CB_SurvivalChallenge_Station_15' THEN return 'Station15' || '_' || in_dimension_index;
		WHEN 'CB_Story_WaterFatManor' THEN return 'WaterFat' || '_' || in_dimension_index;
		WHEN 'Story_ProcesVerbal' THEN return 'ProcesVerbal' || '_' || in_dimension_index;
		WHEN 'DLC_Story_LostHarvest' THEN return 'LostHarvest' || '_' || in_dimension_index;
		WHEN 'DLC_Story_LostHarvest_EcolabA' THEN return 'LostHarvest_EcolabA' || '_' || in_dimension_index;
		WHEN 'DLC_Story_LostHarvest_EcolabB' THEN return 'LostHarvest_EcolabB' || '_' || in_dimension_index;
		WHEN 'DLC_Story_LostHarvest_ForgottenLab' THEN return 'LostHarvest_ForgottenLab' || '_' || in_dimension_index;
		WHEN 'Story_ArtOfKanly' THEN return 'ArtOfKanly' || '_' || in_dimension_index;
		WHEN 'Story_HeighlinerDungeon' THEN return 'HeighlinerDungeon' || '_' || in_dimension_index;
		WHEN 'CB_Dungeon_Hephaestus' THEN return 'WreckOfHephaestusDungeon' || '_' || in_dimension_index;
		WHEN 'CB_Dungeon_OldCarthag' THEN return 'OldCarthagDungeon' || '_' || in_dimension_index;
		WHEN 'CB_Story_BanditFortress01' THEN return 'SandfliesFortress' || '_' || in_dimension_index;
		WHEN 'CB_Overland_S_05' THEN return 'ClosedOffTestingStationIsland' || '_' || in_dimension_index;
		WHEN 'CB_Overland_S_06' THEN return 'GroundVehicleTimeTrialIsland' || '_' || in_dimension_index;
		WHEN 'CB_Overland_S_04' THEN return 'ErythriteCaveIsland' || '_' || in_dimension_index;
		WHEN 'CB_Overland_M_01' THEN return 'RadioactiveShipwreck' || '_' || in_dimension_index;
		WHEN 'Story_Faction_Outpost_Hark' THEN return 'Story_Faction_Outpost_Hark' || '_' || in_dimension_index;
		WHEN 'Story_Faction_Outpost_Atre' THEN return 'Story_Faction_Outpost_Atre' || '_' || in_dimension_index;
		WHEN 'CB_Ecolab_Bronze_Green_089' THEN return 'RadiationDungeon' || '_' || in_dimension_index;
		WHEN 'CB_Ecolab_Bronze_Green_152' THEN return 'ElectricityDungeon' || '_' || in_dimension_index;
		WHEN 'CB_Ecolab_Bronze_Green_195' THEN return 'PoisonDungeon' || '_' || in_dimension_index;
		WHEN 'CB_Ecolab_Bronze_Green_024' THEN return 'DarknessDungeon' || '_' || in_dimension_index;
		WHEN 'CB_Ecolab_Bronze_Green_136' THEN return 'FireDungeon' || '_' || in_dimension_index;
		WHEN 'CB_Overland_S_07' THEN return 'TheRuinsOfTsimpo' || '_' || in_dimension_index;
		WHEN 'CB_Story_DestroyedZanovar' THEN return 'DestroyedZanovar' || '_' || in_dimension_index;
		WHEN 'CB_Story_OrbitalMonitor' THEN return 'OrbitalMonitor' || '_' || in_dimension_index;
		WHEN 'CB_Dungeon_TheFacility' THEN return 'FacilityDungeon' || '_' || in_dimension_index;
		WHEN 'CB_Dungeon_ThePit' THEN return 'PitDungeon' || '_' || in_dimension_index;
		WHEN 'Overmap' THEN
			IF in_dimension_index = 0 THEN
				return 'Overland';
			END IF;
		WHEN 'Survival_1' THEN
			CASE in_dimension_index
				WHEN 0 THEN return 'Abbir';
				WHEN 1 THEN return 'Alraab';
				WHEN 2 THEN return 'Barkan';
				WHEN 3 THEN return 'Coanua';
				WHEN 4 THEN return 'Fajr Kulon';
				WHEN 5 THEN return 'Gara';
				WHEN 6 THEN return 'Hajar';
				WHEN 7 THEN return 'Jacurutu';
				WHEN 8 THEN return 'Kathib';
				WHEN 9 THEN return 'Legg';
				WHEN 10 THEN return 'Makab';
				WHEN 11 THEN return 'Nadir';
				WHEN 12 THEN return 'Ramal';
				WHEN 13 THEN return 'Rifana';
				WHEN 14 THEN return 'Sandrat';
				WHEN 15 THEN return 'Saajid';
				WHEN 16 THEN return 'Tabr Sink';
				WHEN 17 THEN return 'Tharwa';
				WHEN 18 THEN return 'Umbu';
				WHEN 19 THEN return 'Yaracuwan';
				WHEN 20 THEN return 'al-Mut';
				WHEN 21 THEN return 'Altuyur';
				WHEN 22 THEN return 'Ammit';
				WHEN 23 THEN return 'Ashia';
				WHEN 24 THEN return 'Eaqrab';
				WHEN 25 THEN return 'Hagga';
				WHEN 26 THEN return 'Hua';
				WHEN 27 THEN return 'Katal';
				WHEN 28 THEN return 'Khafash';
				WHEN 29 THEN return 'Matar';
				WHEN 30 THEN return 'Rabie';
				WHEN 31 THEN return 'Rajifiri';
				WHEN 32 THEN return 'Remmel';
				WHEN 33 THEN return 'Sahr';
				WHEN 34 THEN return 'Saqer';
				WHEN 35 THEN return 'Ta''lab';
				WHEN 36 THEN return 'Tarl';
				WHEN 37 THEN return 'Tasmin Sink';
				WHEN 38 THEN return 'Thueban';
				WHEN 39 THEN return 'Tuono';
            ELSE
                return 'Survival' || '_' || in_dimension_index;
			END CASE;
		ELSE
			-- Do nothing
	END CASE;

	-- DeepDesert per-partition handling: if all 9 partitions exist, assign based on ordering
	IF in_map = 'DeepDesert_1' THEN
		SELECT count(*) INTO tmp_count FROM world_partition WHERE map = 'DeepDesert_1' AND dimension_index = in_dimension_index;
		IF tmp_count = 9 AND in_partition_id IS NOT NULL THEN
			RETURN (
				WITH chess_notation AS (
					SELECT label, ROW_NUMBER() OVER (ORDER BY null) AS row_num
					FROM (select * from UNNEST(ARRAY['A1', 'B1', 'C1', 'A2', 'B2', 'C2', 'A3', 'B3', 'C3']) as label) as label_list
				),
				partitions AS (
					SELECT partition_id, ROW_NUMBER() OVER (
						order by
							coalesce(partition_definition->'box', partition_definition->'boxes'->0)->>'max_x',
							coalesce(partition_definition->'box', partition_definition->'boxes'->0)->>'max_y',
							coalesce(partition_definition->'box', partition_definition->'boxes'->0)->>'min_x',
							coalesce(partition_definition->'box', partition_definition->'boxes'->0)->>'min_y'
						) AS row_num
					FROM world_partition
					where map = 'DeepDesert_1' AND dimension_index = in_dimension_index
				)
				SELECT 'DeepDesert_' || cn.label
				FROM chess_notation cn
				JOIN partitions p ON cn.row_num = p.row_num
				WHERE p.partition_id = in_partition_id
				LIMIT 1
			);
		END IF;
	END IF;

	IF in_partition_id IS NOT NULL THEN
		SELECT coalesce(partition_definition->'box', partition_definition->'boxes'->0)->>'max_x', coalesce(partition_definition->'box', partition_definition->'boxes'->0)->>'max_y', coalesce(partition_definition->'box', partition_definition->'boxes'->0)->>'min_x', coalesce(partition_definition->'box', partition_definition->'boxes'->0)->>'min_y'
			INTO tmp_box_max_x, tmp_box_max_y, tmp_box_min_x, tmp_box_min_y
		FROM world_partition
		WHERE partition_id = in_partition_id
		LIMIT 1;

		IF tmp_box_max_x IS NOT NULL AND tmp_box_max_x IN ('1.0','1') AND tmp_box_max_y IN ('1.0','1') AND tmp_box_min_x IN ('0.0','0') AND tmp_box_min_y IN ('0.0','0') THEN
			RETURN upgrade_map_name(in_map) || '_' || in_dimension_index;
		END IF;
	ELSE
		-- If we don't have a partition id, try to read any partition for that map/dimension
		SELECT coalesce(partition_definition->'box', partition_definition->'boxes'->0)->>'max_x', coalesce(partition_definition->'box', partition_definition->'boxes'->0)->>'max_y', coalesce(partition_definition->'box', partition_definition->'boxes'->0)->>'min_x', coalesce(partition_definition->'box', partition_definition->'boxes'->0)->>'min_y'
			INTO tmp_box_max_x, tmp_box_max_y, tmp_box_min_x, tmp_box_min_y
		FROM world_partition
		WHERE map = in_map AND dimension_index = in_dimension_index
		LIMIT 1;

		IF tmp_box_max_x IS NOT NULL AND tmp_box_max_x IN ('1.0','1') AND tmp_box_max_y IN ('1.0','1') AND tmp_box_min_x IN ('0.0','0') AND tmp_box_min_y IN ('0.0','0') THEN
			RETURN upgrade_map_name(in_map) || '_' || in_dimension_index;
		END IF;
	END IF;

	RETURN NULL;
END;
$function$
