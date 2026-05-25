-- get_battlegroup_close_date() -> timestamp without time zone
-- oid: 58286  kind: FUNCTION  category: battlegroup

CREATE OR REPLACE FUNCTION dune.get_battlegroup_close_date()
 RETURNS timestamp without time zone
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN (SELECT farm_variables.battlegroup_close_date from farm_variables);
END
$function$
