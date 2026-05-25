-- coriolis_update_seed(in_server_info dune.serverinfo, in_new_coriolis_seed integer, in_map_info dune.coriolismapinfo) -> void
-- oid: 58180  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.coriolis_update_seed(in_server_info dune.serverinfo, in_new_coriolis_seed integer, in_map_info dune.coriolismapinfo)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	old_farm_coriolis_seed Integer;
	old_map_coriolis_seed Integer;
	old_partition_coriolis_seed Integer;
BEGIN
	LOCK TABLE world_farm_reset_seed, world_map_reset_seed, world_partition_reset_seed IN EXCLUSIVE MODE;

	SELECT INTO old_farm_coriolis_seed world_reset_seed FROM world_farm_reset_seed WHERE onerow_id = TRUE limit 1;
	UPDATE world_farm_reset_seed SET world_reset_seed = in_new_coriolis_seed WHERE onerow_id = TRUE;

	SELECT INTO old_map_coriolis_seed world_reset_seed FROM world_map_reset_seed WHERE map = in_server_info.map limit 1;
	INSERT INTO world_map_reset_seed (map, world_reset_seed) Values(in_server_info.map, in_new_coriolis_seed)
		ON CONFLICT(map) DO
		UPDATE SET world_reset_seed = in_new_coriolis_seed;

	SELECT INTO old_partition_coriolis_seed world_reset_seed FROM world_partition_reset_seed WHERE partition_id = in_server_info.partition_id limit 1;
	IF in_server_info.partition_id IS NOT NULL
	THEN
		INSERT INTO world_partition_reset_seed (partition_id, world_reset_seed) Values(in_server_info.partition_id, in_new_coriolis_seed)
			ON CONFLICT(partition_id) DO
			UPDATE SET world_reset_seed = in_new_coriolis_seed;
	END IF;

	IF old_farm_coriolis_seed IS NULL OR old_farm_coriolis_seed <> in_new_coriolis_seed
	THEN
		PERFORM coriolis_cleanup_farm(in_server_info, in_map_info);
	END IF;

	IF in_map_info.is_affected_by_coriolis
	THEN
		IF old_map_coriolis_seed IS NULL OR old_map_coriolis_seed <> in_new_coriolis_seed
		THEN
			PERFORM corilis_cleanup_map(in_server_info, in_map_info);
		END IF;

		IF (in_server_info.partition_id IS NOT NULL AND (old_partition_coriolis_seed IS NULL OR old_partition_coriolis_seed <> in_new_coriolis_seed)) OR
		   (old_map_coriolis_seed IS NULL OR old_map_coriolis_seed <> in_new_coriolis_seed)
		THEN
			PERFORM coriolis_cleanup_partition(in_server_info, in_map_info);
		END IF;
	END IF;
END
$function$
