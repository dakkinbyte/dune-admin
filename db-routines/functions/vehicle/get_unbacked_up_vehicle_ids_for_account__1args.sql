-- get_unbacked_up_vehicle_ids_for_account(in_account_id bigint) -> TABLE(vehicle_id bigint)
-- oid: 58361  kind: FUNCTION  category: vehicle

CREATE OR REPLACE FUNCTION dune.get_unbacked_up_vehicle_ids_for_account(in_account_id bigint)
 RETURNS TABLE(vehicle_id bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
        SELECT v.id
		FROM vehicles v
		JOIN permission_actor_rank par ON v.id = par.permission_actor_id
		JOIN player_state ps ON par.player_id = ps.player_controller_id
		left join backup_vehicles bv ON v.id = bv.vehicle_id
		WHERE ps.account_id = in_account_id
			AND bv.vehicle_id IS NULL;
END
$function$
