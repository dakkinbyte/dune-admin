-- delete_markers_by_id(in_marker_ids integer[]) -> void
-- oid: 58223  kind: FUNCTION  category: markers

CREATE OR REPLACE FUNCTION dune.delete_markers_by_id(in_marker_ids integer[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM markers WHERE marker_hash_id = ANY (in_marker_ids);
END
$function$
