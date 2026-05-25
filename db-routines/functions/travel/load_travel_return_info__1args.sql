-- load_travel_return_info(in_player_controller_id bigint) -> TABLE(map text, transform dune.transform)
-- oid: 58465  kind: FUNCTION  category: travel

CREATE OR REPLACE FUNCTION dune.load_travel_return_info(in_player_controller_id bigint)
 RETURNS TABLE(map text, transform dune.transform)
 LANGUAGE plpgsql
AS $function$
begin
	return query
	select travel_return_info.map, travel_return_info.transform
	from travel_return_info
	where player_controller_id = in_player_controller_id;
end
$function$
