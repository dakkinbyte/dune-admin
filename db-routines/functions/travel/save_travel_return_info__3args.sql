-- save_travel_return_info(in_player_controller_id bigint, in_map text, in_transform dune.transform) -> void
-- oid: 58573  kind: FUNCTION  category: travel

CREATE OR REPLACE FUNCTION dune.save_travel_return_info(in_player_controller_id bigint, in_map text, in_transform dune.transform)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
	insert into travel_return_info(
		"player_controller_id", "map", "transform"
	)
	values(
			  in_player_controller_id, in_map, in_transform
	)
	on conflict (player_controller_id) do update
		set
			"map" = EXCLUDED.map,
			"transform" = EXCLUDED.transform;
end
$function$
