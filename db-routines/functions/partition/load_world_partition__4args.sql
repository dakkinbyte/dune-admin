-- load_world_partition(in_map_name text, in_server_id text, in_desired_dimension_index bigint, in_desired_partition_id bigint) -> TABLE(partition_id bigint, partition_definition jsonb, dimension_index integer, blocked boolean, label text)
-- oid: 58468  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.load_world_partition(in_map_name text, in_server_id text, in_desired_dimension_index bigint DEFAULT 0, in_desired_partition_id bigint DEFAULT NULL::bigint)
 RETURNS TABLE(partition_id bigint, partition_definition jsonb, dimension_index integer, blocked boolean, label text)
 LANGUAGE plpgsql
AS $function$
DECLARE
	tmp_partition RECORD;
BEGIN
	-- First check if the server already have a partition assigned
	SELECT INTO tmp_partition wp.partition_id, wp.partition_definition, wp.dimension_index, wp.blocked, wp.label
		FROM world_partition wp
		WHERE server_id = in_server_id AND wp.map = in_map_name AND wp.dimension_index = in_desired_dimension_index;
	IF tmp_partition.partition_id IS NOT NULL THEN
		RETURN QUERY SELECT tmp_partition.partition_id, tmp_partition.partition_definition, tmp_partition.dimension_index, tmp_partition.blocked, tmp_partition.label;
		RETURN;
	END IF;

	-- No partition assigned, so try to find an unassigned partition for this server
	SELECT INTO tmp_partition wp.partition_id, wp.partition_definition, wp.dimension_index, wp.blocked, wp.label
		FROM world_partition wp
		WHERE (server_id IS NULL OR server_id NOT IN (SELECT * FROM active_server_ids)) AND wp.map = in_map_name AND wp.dimension_index = in_desired_dimension_index
		ORDER BY (wp.partition_id = in_desired_partition_id) DESC, wp.partition_definition->'type', wp.partition_definition->'index', wp.partition_definition->'box'->'min_x', wp.partition_definition->'box'->'min_y'
		LIMIT 1
		FOR UPDATE SKIP LOCKED;
	IF tmp_partition.partition_id IS NULL THEN
		RETURN;
	ELSE
		-- Fake a server
		INSERT INTO farm_state(server_id, farm_id, outgoing_s2s_connections, incoming_s2s_connections, connected_players, igw_addr, igw_port, game_addr, game_port, map, revision)
			VALUES (in_server_id, '0', 0, 0, 0, '0.0.0.0', 0, '0.0.0.0', 0, '', 0) ON CONFLICT DO NOTHING;
		UPDATE world_partition SET server_id = in_server_id WHERE world_partition.partition_id = tmp_partition.partition_id;
		NOTIFY world_partition_update;
		RETURN QUERY SELECT tmp_partition.partition_id, tmp_partition.partition_definition, tmp_partition.dimension_index, tmp_partition.blocked, tmp_partition.label;
		RETURN;
	END IF;
END
$function$
