-- _user_data_encryption_setup_enabled(key_hash bytea) -> void
-- oid: 58114  kind: FUNCTION  category: encryption

CREATE OR REPLACE FUNCTION dune._user_data_encryption_setup_enabled(key_hash bytea)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
	if key_hash is null then
		raise exception 'User-data encryption requested but the server does not have the encryption key set';
	end if;

	if (select get_stored_user_data_encryption_taint_xmax()) is not null then
		-- should have been filtered by the main setup function
		raise exception 'Trying to enable encryption on a tainted data';
	end if;

	execute format($x$
		create or replace function get_stored_user_data_encryption_key_hash() returns bytea immutable
    		as $y$select '%s'::bytea;$y$ language sql;
	$x$, key_hash::text);

    -- the data is encrypted and we have the key
	create or replace function get_stored_user_data_encryption_status() returns UserDataEncryptionStatus immutable
		as $x$select 'Enabled'::UserDataEncryptionStatus;$x$ language sql;

	-- We may bake the key into the function code but then dumping the functions will reveal the key
	create or replace function encrypt_user_data(in_data text) returns bytea immutable as $x$
		select ext.encrypt(convert_to(in_data, 'utf8'), current_setting('funcom.user_data_encryption_key')::bytea, 'aes')::bytea;
	$x$ language sql;

	create or replace function decrypt_user_data(in_encrypted_data bytea) returns text immutable as $x$
		select convert_from(
			ext.decrypt(in_encrypted_data, current_setting('funcom.user_data_encryption_key')::bytea, 'aes'), 'utf8'
		);
	$x$ language sql;
end
$function$
