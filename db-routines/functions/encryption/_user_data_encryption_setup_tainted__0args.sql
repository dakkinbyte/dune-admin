-- _user_data_encryption_setup_tainted() -> void
-- oid: 58115  kind: FUNCTION  category: encryption

CREATE OR REPLACE FUNCTION dune._user_data_encryption_setup_tainted()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
	-- we not replacing get_stored_user_data_encryption_key_hash()
	if (select get_stored_user_data_encryption_key_hash()) is null then
		-- should have been filtered by the main setup function
		raise exception 'Tainted but the data is not encrypted in the first place';
	end if;

	execute format($x$
		create or replace function get_stored_user_data_encryption_taint_xmax() returns int8 immutable
    		as 'select %s;' language sql;
	$x$, pg_current_xact_id());

	-- the data is encrypted but we don't have the key (or don't want to)
	create or replace function get_stored_user_data_encryption_status() returns UserDataEncryptionStatus immutable
		as $x$select 'Tainted'::UserDataEncryptionStatus;$x$ language sql;

	create or replace function encrypt_user_data(in_data text) returns bytea immutable
		as $x$select convert_to(in_data, 'utf8')$x$ language sql;

	-- We may use the taint xmax to differentiate between encrypted/unencrypted data for that we would have to pass the
	-- xmin into the function (which is xid and not xid8)
	create or replace function decrypt_user_data(in_encrypted_data bytea) returns text immutable
		as $x$select encode(in_encrypted_data, 'hex');$x$ language sql;
end
$function$
