-- remove_communinet_player_channel(in_account_id bigint, in_channel_name text) -> void
-- oid: 58517  kind: FUNCTION  category: communinet

CREATE OR REPLACE FUNCTION dune.remove_communinet_player_channel(in_account_id bigint, in_channel_name text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    DELETE FROM communinet_player_channels WHERE account_id = in_account_id AND channel_name = in_channel_name;
END
$function$
