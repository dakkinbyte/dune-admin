-- get_exchange_inventory_id(in_exchange_id bigint) -> bigint
-- oid: 58300  kind: FUNCTION  category: exchange

CREATE OR REPLACE FUNCTION dune.get_exchange_inventory_id(in_exchange_id bigint)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	inv_id BIGINT;
BEGIN
	SELECT INTO inv_id id FROM inventories WHERE "exchange_id" = in_exchange_id;
	IF inv_id IS NULL THEN
		INSERT INTO inventories("id", exchange_id) VALUES(DEFAULT, in_exchange_id) RETURNING id INTO inv_id;
	END IF;
	RETURN inv_id;
END $function$
