-- update_communinet_player_data(in_account_id bigint, in_is_active boolean, in_selected_channel_name text) -> void
-- oid: 58616  kind: FUNCTION  category: communinet

CREATE OR REPLACE FUNCTION dune.update_communinet_player_data(in_account_id bigint, in_is_active boolean, in_selected_channel_name text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO communinet_player(account_id, is_active, selected_channel_name) VALUES (in_account_id, in_is_active, in_selected_channel_name)
	ON CONFLICT(account_id) DO UPDATE SET is_active = in_is_active, selected_channel_name = in_selected_channel_name WHERE communinet_player.account_id = in_account_id;
END $function$
