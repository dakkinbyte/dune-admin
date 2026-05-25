-- get_dune_exchange_accesspoint_id(in_exchange_id bigint, in_name text) -> bigint
-- oid: 58296  kind: FUNCTION  category: exchange

CREATE OR REPLACE FUNCTION dune.get_dune_exchange_accesspoint_id(in_exchange_id bigint, in_name text)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	new_ap_id BIGINT;
	ap_id BIGINT;
BEGIN
	INSERT INTO dune_exchange_accesspoints(exchange_id, name) VALUES(in_exchange_id, in_name) ON CONFLICT DO NOTHING RETURNING id INTO new_ap_id;
	SELECT INTO ap_id COALESCE(new_ap_id, id) FROM dune_exchange_accesspoints WHERE exchange_id = in_exchange_id AND name = in_name;

	return ap_id;
END $function$
