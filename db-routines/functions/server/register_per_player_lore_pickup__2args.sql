-- register_per_player_lore_pickup(in_lore_pickup_ids text[], in_use_temporary boolean) -> SETOF smallint
-- oid: 58510  kind: FUNCTION  category: server

CREATE OR REPLACE FUNCTION dune.register_per_player_lore_pickup(in_lore_pickup_ids text[], in_use_temporary boolean)
 RETURNS SETOF smallint
 LANGUAGE plpgsql
AS $function$
BEGIN
	IF in_use_temporary THEN
		RETURN query select * from register_temporary_lore_pickup(in_lore_pickup_ids);
	ELSE
		RETURN query select * from register_lore_pickup(in_lore_pickup_ids);
	END IF;
END
$function$
