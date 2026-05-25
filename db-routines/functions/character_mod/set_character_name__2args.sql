-- set_character_name(in_account_id bigint, in_name text) -> void
-- oid: 58591  kind: FUNCTION  category: character_mod

CREATE OR REPLACE FUNCTION dune.set_character_name(in_account_id bigint, in_name text)
 RETURNS void
 LANGUAGE sql
AS $function$
    update encrypted_player_state set encrypted_character_name=encrypt_user_data(in_name) where account_id=in_account_id;
$function$
