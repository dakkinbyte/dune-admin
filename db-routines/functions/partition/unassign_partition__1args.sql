-- unassign_partition(in_server_id text) -> boolean
-- oid: 58614  kind: FUNCTION  category: partition

CREATE OR REPLACE FUNCTION dune.unassign_partition(in_server_id text)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_affected_rows BigInt;
BEGIN
	UPDATE world_partition SET server_id = null WHERE server_id = in_server_id;
	get diagnostics v_affected_rows = ROW_COUNT;

	-- If we didn't actually unassign anything, we have no need to trigger the notification (as nothing changed)
	if v_affected_rows > 0 then
		NOTIFY world_partition_update;
		return true;
	end if;
	return false;
END $function$
