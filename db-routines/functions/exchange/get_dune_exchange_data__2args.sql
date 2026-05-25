-- get_dune_exchange_data(in_exchange_id bigint, in_controller_id bigint) -> dune.loadexchangedataresult
-- oid: 58297  kind: FUNCTION  category: exchange

CREATE OR REPLACE FUNCTION dune.get_dune_exchange_data(in_exchange_id bigint, in_controller_id bigint)
 RETURNS dune.loadexchangedataresult
 LANGUAGE plpgsql
AS $function$
DECLARE
	result LoadExchangeDataResult;
BEGIN
	SELECT INTO result.exchange_name exchange_name FROM dune_exchanges WHERE id=in_exchange_id;
	SELECT INTO result.used_order_slots get_dune_exchange_used_order_slots(in_controller_id);

	RETURN result;
END $function$
