-- cleanup_accounts_marked_for_deletion_in_fls(in_account_ids text[]) -> void
-- oid: 58172  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune.cleanup_accounts_marked_for_deletion_in_fls(in_account_ids text[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
	perform delete_account(id, 'deleted in fls') from unnest(in_account_ids) as id;
end
$function$
