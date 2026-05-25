-- update_marker_ids(in_old_ids integer[], in_new_ids integer[]) -> void
-- oid: 58626  kind: FUNCTION  category: markers

CREATE OR REPLACE FUNCTION dune.update_marker_ids(in_old_ids integer[], in_new_ids integer[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE markers SET marker_hash_id = data_table.new_id, marker.z = 0 from (select unnest(in_old_ids) as old_id, unnest(in_new_ids) as new_id) as data_table WHERE markers.marker_hash_id = data_table.old_id;
END; $function$
