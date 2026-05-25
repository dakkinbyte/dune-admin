-- gather_ownerless_actors_on_server(in_server_info dune.serverinfo) -> SETOF dune.actorspawninfo
-- oid: 58266  kind: FUNCTION  category: actors

CREATE OR REPLACE FUNCTION dune.gather_ownerless_actors_on_server(in_server_info dune.serverinfo)
 RETURNS SETOF dune.actorspawninfo
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
		SELECT a.id, a.class as class_name, a.transform, a.partition_id, a.dimension_index FROM actors as a
		WHERE a.owner_account_id is null AND server_info_match(a, in_server_info);
END;
$function$
