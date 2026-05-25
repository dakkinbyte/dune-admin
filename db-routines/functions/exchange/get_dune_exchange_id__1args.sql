-- get_dune_exchange_id(in_name text) -> bigint
-- oid: 58298  kind: FUNCTION  category: exchange

CREATE OR REPLACE FUNCTION dune.get_dune_exchange_id(in_name text)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	new_exchange_id BIGINT;
	exchange_id BIGINT;
BEGIN
	INSERT INTO dune_exchanges(exchange_name, inventory_id) VALUES(in_name, NULL) ON CONFLICT DO NOTHING RETURNING id INTO new_exchange_id;
	SELECT INTO exchange_id COALESCE(new_exchange_id, id) FROM dune_exchanges WHERE exchange_name = in_name;
	RETURN exchange_id;
END $function$
