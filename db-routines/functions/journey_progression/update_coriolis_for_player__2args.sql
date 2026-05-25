-- update_coriolis_for_player(in_controller_id bigint, OUT out_was_coriolis_processed boolean) -> boolean
-- oid: 58618  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.update_coriolis_for_player(in_controller_id bigint, OUT out_was_coriolis_processed boolean)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
begin
	SELECT is_coriolis_processed INTO out_was_coriolis_processed
		FROM player_state WHERE player_controller_id = in_controller_id;
	UPDATE player_state SET is_coriolis_processed = TRUE WHERE player_controller_id = in_controller_id;
end
$function$
