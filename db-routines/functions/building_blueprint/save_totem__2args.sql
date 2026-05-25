-- save_totem(in_id bigint, in_data dune.totemsavedata) -> void
-- oid: 58571  kind: FUNCTION  category: building_blueprint

CREATE OR REPLACE FUNCTION dune.save_totem(in_id bigint, in_data dune.totemsavedata)
 RETURNS void
 LANGUAGE sql
BEGIN ATOMIC
 INSERT INTO dune.totems (id, landclaim_vertical_level, last_backup_timestamp, landclaim_original_global_location, landclaim_original_global_yaw_rotation)
   VALUES (save_totem.in_id, (save_totem.in_data).landclaim_vertical_level, (save_totem.in_data).last_backup_timestamp, (save_totem.in_data).landclaim_original_global_location, (save_totem.in_data).landclaim_original_global_yaw_rotation) ON CONFLICT(id) DO UPDATE SET landclaim_vertical_level = excluded.landclaim_vertical_level, last_backup_timestamp = excluded.last_backup_timestamp, landclaim_original_global_location = excluded.landclaim_original_global_location, landclaim_original_global_yaw_rotation = excluded.landclaim_original_global_yaw_rotation;
END
