-- _user_data_encryption_initially_encrypt_existing_data() -> void
-- oid: 58113  kind: FUNCTION  category: encryption

CREATE OR REPLACE FUNCTION dune._user_data_encryption_initially_encrypt_existing_data()
 RETURNS void
 LANGUAGE sql
AS $function$
	update encrypted_accounts set encrypted_funcom_id=encrypt_user_data(convert_from(encrypted_funcom_id, 'utf8'));
	update encrypted_player_state set
		encrypted_character_name=encrypt_user_data(convert_from(encrypted_character_name, 'utf8'));
$function$
