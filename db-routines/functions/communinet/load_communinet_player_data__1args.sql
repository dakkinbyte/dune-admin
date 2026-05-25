-- load_communinet_player_data(in_account_id bigint) -> TABLE(is_active boolean, selected_channel_name text, channel_name text, is_tuned boolean)
-- oid: 58450  kind: FUNCTION  category: communinet

CREATE OR REPLACE FUNCTION dune.load_communinet_player_data(in_account_id bigint)
 RETURNS TABLE(is_active boolean, selected_channel_name text, channel_name text, is_tuned boolean)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
	SELECT cp.is_active, cp.selected_channel_name, cpc.channel_name, cpc.is_tuned
	FROM communinet_player AS cp  JOIN communinet_player_channels as cpc
	ON cp.account_id = cpc.account_id
	WHERE cpc.account_id = in_account_id;
END; $function$
