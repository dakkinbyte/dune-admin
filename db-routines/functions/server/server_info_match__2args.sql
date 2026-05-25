-- server_info_match(in_actor dune.actors, in_server_info dune.serverinfo) -> boolean
-- oid: 58586  kind: FUNCTION  category: server

CREATE OR REPLACE FUNCTION dune.server_info_match(in_actor dune.actors, in_server_info dune.serverinfo)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE STRICT
AS $function$
BEGIN
	return in_actor.map = in_server_info.map
        AND in_actor.dimension_index = in_server_info.dimension_index
        AND (
            in_actor.partition_id IS NULL
            OR
            in_server_info.partition_id IS NULL
            OR
            in_actor.partition_id = in_server_info.partition_id
        );
END
$function$
