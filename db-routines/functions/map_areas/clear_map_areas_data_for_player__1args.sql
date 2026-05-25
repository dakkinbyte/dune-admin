-- clear_map_areas_data_for_player(in_id bigint) -> void
-- oid: 58174  kind: FUNCTION  category: map_areas

CREATE OR REPLACE FUNCTION dune.clear_map_areas_data_for_player(in_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    DELETE FROM map_areas WHERE account_id = in_id;
END
$function$
