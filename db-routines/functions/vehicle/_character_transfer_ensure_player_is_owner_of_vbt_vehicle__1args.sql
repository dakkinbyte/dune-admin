-- _character_transfer_ensure_player_is_owner_of_vbt_vehicle(in_vehicle_id bigint[]) -> void
-- oid: 58100  kind: FUNCTION  category: vehicle

CREATE OR REPLACE FUNCTION dune._character_transfer_ensure_player_is_owner_of_vbt_vehicle(in_vehicle_id bigint[])
 RETURNS void
 LANGUAGE sql
AS $function$
	update permission_actor_rank set "rank" = 1 where permission_actor_id = any(in_vehicle_id);
$function$
