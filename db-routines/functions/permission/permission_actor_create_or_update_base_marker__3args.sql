-- permission_actor_create_or_update_base_marker(in_actor_id bigint, in_player_id bigint, in_rank smallint) -> void
-- oid: 58485  kind: FUNCTION  category: permission

CREATE OR REPLACE FUNCTION dune.permission_actor_create_or_update_base_marker(in_actor_id bigint, in_player_id bigint, in_rank smallint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	out_marker_type TEXT := 'HomeBase';
	out_owner_id BIGINT;
	out_owner_name Text;
	out_dimension_index INTEGER;
	out_x REAL;
	out_y REAL;
	out_z REAL;
	out_totem_name Text;
	out_map_name Text;
	out_map_name_id SMALLINT;
	out_actor_type smallint;
BEGIN

	-- Get owner data
	SELECT player_id, character_name
	INTO out_owner_id, out_owner_name
	FROM permission_actor_rank
	JOIN player_state on player_controller_id = player_id
	WHERE rank = 1::smallint AND permission_actor_id = in_actor_id
	LIMIT 1;

	-- Get target and totem data
	SELECT dimension_index, (transform).location.x, (transform).location.y, (transform).location.z, actor_name, map, actor_type
	INTO out_dimension_index, out_x, out_y, out_z, out_totem_name, out_map_name, out_actor_type
	FROM permission_actor_rank
	JOIN permission_actor on actor_id = permission_actor_id
	JOIN player_state on player_controller_id = player_id
	JOIN actors ON permission_actor_id = actors.id
	WHERE permission_actor_id = in_actor_id	AND player_id = in_player_id
	LIMIT 1;

	SELECT map_name_id
	INTO out_map_name_id
	FROM map_names
	WHERE map_name = out_map_name;

	IF out_actor_type = 3 OR out_actor_type = 4 THEN -- Totem || TotemSmall
		INSERT INTO markers ("dimension_index", "marker_hash_id", "map_name_id", "marker", "area_id", "area_radius", "long_range", "payload")
		VALUES(out_dimension_index,
			in_actor_id,
			out_map_name_id,
			ROW(
				out_marker_type,
				out_x, out_y, out_z,
				'EMarkerPayloadType::Permissions'
			)::MARKER,
			0,
			0,
			FALSE,
			jsonb_build_object(
				'OwnerUID', out_owner_id,
				'OwnerName', out_owner_name,
				'TotemName', out_totem_name,
				'TotemId', in_actor_id
			)
		)
		ON CONFLICT (marker_hash_id, dimension_index, map_name_id)
		DO UPDATE SET
		marker = EXCLUDED.marker;

		INSERT INTO player_markers ("dimension_index", "player_id", "marker_hash_id", "map_name_id", "discovery_level", "discovery_method", "payload")
		VALUES(out_dimension_index,
			in_player_id,
			in_actor_id,
			out_map_name_id,
			3, -- EMarkerDiscoveryLevel::Discovered
			10, -- EMarkerDiscoveryMethod::Permissions
			'{}'::JSONB
		)
		ON CONFLICT (dimension_index, player_id, marker_hash_id, map_name_id)
		DO NOTHING;
	END IF;

END
$function$
