-- setup_user_data_encryption(IN in_enable boolean) -> void
-- oid: 58597  kind: PROCEDURE  category: encryption

CREATE OR REPLACE PROCEDURE dune.setup_user_data_encryption(IN in_enable boolean)
 LANGUAGE plpgsql
AS $procedure$
declare
	encryption_key Text;
    encryption_key_hash bytea;
    stored_encryption_key_hash bytea;
	stored_encryption_status UserDataEncryptionStatus;
begin
	select current_setting('funcom.user_data_encryption_key', true) into encryption_key;
    -- might be null if the encryption_key is null
    select ext.digest(encryption_key, 'md5') into encryption_key_hash;
    -- might be null if the stored data is not encrypted
    select get_stored_user_data_encryption_key_hash() into stored_encryption_key_hash;

	-- should never be null
	select get_stored_user_data_encryption_status() into stored_encryption_status;

    drop index if exists encrypted_player_state_character_name_gin;

	if stored_encryption_status = 'Disabled' then
		if in_enable then
			perform _user_data_encryption_setup_enabled(encryption_key_hash);
			perform _user_data_encryption_initially_encrypt_existing_data();
		else
			-- technically we shouldn't do anything but let's just validate a few things
			-- we not replacing get_stored_user_data_encryption_key_hash()
			if (select get_stored_user_data_encryption_key_hash()) is not null then
				-- should have been filtered by the main setup function
				raise exception 'The data is encrypted, should use the taint version';
			end if;

			if (select get_stored_user_data_encryption_taint_xmax()) is not null then
				-- should have been filtered by the main setup function
				raise exception 'The data is tainted, should use the taint version';
			end if;
		end if;
	elseif stored_encryption_status = 'Tainted' then
		-- doesn't matter what we want, we get the tainted version
		perform _user_data_encryption_setup_tainted();
	else -- Enabled
		if in_enable is null or in_enable then
			if encryption_key_hash = stored_encryption_key_hash then -- and our key is the same
				perform _user_data_encryption_setup_enabled(encryption_key_hash);
			else
				raise warning 'User-data encryption requested but the data is already encrypted with a different key';
				perform _user_data_encryption_setup_tainted();
			end if;
		else
			raise warning 'User-data encryption not requested but the data is already encrypted';
			perform _user_data_encryption_setup_tainted();
		end if;
	end if;

	commit;

	CREATE INDEX encrypted_player_state_character_name_gin ON encrypted_player_state USING GIN((decrypt_user_data(encrypted_character_name)) ext.gin_trgm_ops);
end
$procedure$
