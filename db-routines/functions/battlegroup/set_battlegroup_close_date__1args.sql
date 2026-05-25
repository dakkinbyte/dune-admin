-- set_battlegroup_close_date(in_close_date timestamp without time zone) -> timestamp without time zone
-- oid: 58589  kind: FUNCTION  category: battlegroup

CREATE OR REPLACE FUNCTION dune.set_battlegroup_close_date(in_close_date timestamp without time zone)
 RETURNS timestamp without time zone
 LANGUAGE plpgsql
AS $function$
BEGIN
	INSERT INTO farm_variables (one_row, battlegroup_close_date) VALUES (true,in_close_date)
	ON CONFLICT (one_row) DO UPDATE SET battlegroup_close_date = in_close_date;
	RETURN (select * from get_battlegroup_close_date());
END
$function$
