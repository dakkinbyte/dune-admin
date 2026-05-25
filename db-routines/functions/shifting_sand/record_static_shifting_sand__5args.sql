-- record_static_shifting_sand(in_id text, in_alpha double precision, in_x double precision, in_y double precision, in_last_modified_time bigint) -> void
-- oid: 58505  kind: FUNCTION  category: shifting_sand

CREATE OR REPLACE FUNCTION dune.record_static_shifting_sand(in_id text, in_alpha double precision, in_x double precision, in_y double precision, in_last_modified_time bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	INSERT INTO shiftingsands_data(id, alpha, x, y, last_modified_time) Values(in_id, in_alpha, in_x, in_y, to_timestamp(in_last_modified_time))
	ON CONFLICT(id) DO UPDATE SET alpha = $2, last_modified_time = to_timestamp(in_last_modified_time);
END $function$
