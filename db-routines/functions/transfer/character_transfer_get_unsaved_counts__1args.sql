-- character_transfer_get_unsaved_counts(in_fls_id text) -> TABLE(unsaved_bases_count bigint, unsaved_vehicles_count bigint)
-- oid: 58162  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune.character_transfer_get_unsaved_counts(in_fls_id text)
 RETURNS TABLE(unsaved_bases_count bigint, unsaved_vehicles_count bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_acc_id BIGINT;
BEGIN
	v_acc_id := (SELECT acc.id FROM encrypted_accounts acc WHERE acc.user = in_fls_id);

	RETURN QUERY
		WITH unbacked_bases AS (
			SELECT COUNT(*) AS count
			FROM get_unsaved_base_totem_ids_for_account(v_acc_id)
		),
		unsaved_vehicles AS (
			SELECT COUNT(*) AS count
			FROM get_unbacked_up_vehicle_ids_for_account(v_acc_id)
		)
		SELECT
			ub.count AS unsaved_bases_count,
			uv.count AS unsaved_vehicles_count
		FROM unbacked_bases ub, unsaved_vehicles uv;
END
$function$
