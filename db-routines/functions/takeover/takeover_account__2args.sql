-- takeover_account(in_user_to_takeover text, in_current_user text) -> void
-- oid: 58601  kind: FUNCTION  category: takeover

CREATE OR REPLACE FUNCTION dune.takeover_account(in_user_to_takeover text, in_current_user text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	current_funcom_id ByteA;
	current_account_id BigInt;

	takeover_funcom_id ByteA;
	takeover_account_id BigInt;
BEGIN
	select "encrypted_funcom_id", "id" into current_funcom_id, current_account_id
		from encrypted_accounts WHERE "user"=in_current_user;

	select "encrypted_funcom_id", "id" into takeover_funcom_id, takeover_account_id
		from encrypted_accounts WHERE "user"=in_user_to_takeover;

	-- Account swap
	UPDATE encrypted_accounts SET "user"=in_current_user || 'TempTakeover' WHERE "id"=current_account_id;
	UPDATE encrypted_accounts SET "user"=in_current_user, "encrypted_funcom_id"=current_funcom_id WHERE "id"=takeover_account_id;
	UPDATE encrypted_accounts SET "user"=in_user_to_takeover, "encrypted_funcom_id"=takeover_funcom_id WHERE "id"=current_account_id;
END
$function$
