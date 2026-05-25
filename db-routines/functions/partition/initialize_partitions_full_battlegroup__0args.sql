-- initialize_partitions_full_battlegroup() -> void
-- oid: 58384  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.initialize_partitions_full_battlegroup()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	perform add_partition_unique('Survival_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('Survival_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 1);
	perform add_partition_unique('Survival_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 2);
	perform add_partition_unique('Survival_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 3);
	perform add_partition_unique('Survival_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 4);
	perform add_partition_unique('Survival_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 5);
	perform add_partition_unique('Survival_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 6);
	perform add_partition_unique('Survival_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 7);
	perform add_partition_unique('Survival_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 8);
	perform add_partition_unique('Survival_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 9);
	perform add_partition_unique('Survival_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 10);
	perform add_partition_unique('Survival_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 11);
	perform add_partition_unique('Survival_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 12);
	perform add_partition_unique('Survival_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 13);
	perform add_partition_unique('Survival_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 14);
	perform add_partition_unique('Survival_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 15);
	perform add_partition_unique('Survival_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 16);
	perform add_partition_unique('Survival_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 17);
	perform add_partition_unique('Survival_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 18);
	perform add_partition_unique('Survival_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 19);
	perform add_partition_unique('SH_HarkoVillage', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('SH_HarkoVillage', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 1);
	perform add_partition_unique('SH_Arrakeen', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('SH_Arrakeen', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 1);
	perform add_partition_unique('SH_FallenLight', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('SH_FallenLight', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 1);
	perform add_partition_unique('CB_Story_Hephaestus', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('CB_Story_Ecolab_Carthag', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('CB_Story_WaterFatManor', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('DeepDesert_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('DeepDesert_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 1);
	perform add_partition_unique('DeepDesert_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 2);
	perform add_partition_unique('Overmap', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('Story_ProcesVerbal', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('DLC_Story_LostHarvest', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('DLC_Story_LostHarvest_EcolabA', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('DLC_Story_LostHarvest_EcolabB', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('DLC_Story_LostHarvest_ForgottenLab', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('Story_ArtOfKanly', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('Story_HeighlinerDungeon', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('CB_Dungeon_Hephaestus', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('CB_Dungeon_OldCarthag', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('CB_Story_BanditFortress01', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('CB_Overland_S_05', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('CB_Overland_S_06', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('CB_Overland_S_04', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('CB_Overland_M_01', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('CB_Overland_S_07', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('Story_Faction_Outpost_Hark', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('Story_Faction_Outpost_Atre', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('CB_Ecolab_Bronze_Green_089', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('CB_Ecolab_Bronze_Green_152', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('CB_Ecolab_Bronze_Green_195', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('CB_Ecolab_Bronze_Green_024', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('CB_Ecolab_Bronze_Green_136', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('PolarCap_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('PolarCap_1', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 1);
	perform add_partition_unique('CB_Story_DestroyedZanovar', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('CB_Story_OrbitalMonitor', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('CB_Dungeon_TheFacility', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('CB_Dungeon_ThePit', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform add_partition_unique('CB_Overland_S_08', '{"box": {"max_x": 1, "max_y": 1, "min_x": 0, "min_y": 0}, "type": "box2d_array"}', 0);
	perform update_partition_labels();
END;
$function$
