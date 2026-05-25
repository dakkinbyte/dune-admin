-- retrieve_all_static_shifting_sand() -> TABLE(out_id text, out_alpha double precision, out_x double precision, out_y double precision, out_last_modified_time bigint)
-- oid: 58536  kind: FUNCTION  category: shifting_sand

CREATE OR REPLACE FUNCTION dune.retrieve_all_static_shifting_sand()
 RETURNS TABLE(out_id text, out_alpha double precision, out_x double precision, out_y double precision, out_last_modified_time bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
        SELECT id, alpha, x, y, EXTRACT(EPOCH FROM last_modified_time)::BIGINT AS last_modified_time FROM shiftingsands_data;
END; $function$
