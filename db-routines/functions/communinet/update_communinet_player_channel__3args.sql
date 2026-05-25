-- update_communinet_player_channel(in_account_id bigint, in_channel_name text, in_is_tuned boolean) -> void
-- oid: 58615  kind: FUNCTION  category: communinet

CREATE OR REPLACE FUNCTION dune.update_communinet_player_channel(in_account_id bigint, in_channel_name text, in_is_tuned boolean)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO communinet_player_channels(account_id, channel_name, is_tuned) VALUES (in_account_id, in_channel_name, in_is_tuned)
	ON CONFLICT(account_id, channel_name) DO UPDATE SET is_tuned = in_is_tuned WHERE communinet_player_channels.account_id = in_account_id AND communinet_player_channels.channel_name = in_channel_name;
END $function$
