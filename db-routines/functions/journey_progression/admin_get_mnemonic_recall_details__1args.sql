-- admin_get_mnemonic_recall_details(in_account_id bigint) -> TABLE(mnemonic_recall_id bigint, lesson_id text, lesson_state bigint, lesson_progress integer)
-- oid: 58134  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.admin_get_mnemonic_recall_details(in_account_id bigint)
 RETURNS TABLE(mnemonic_recall_id bigint, lesson_id text, lesson_state bigint, lesson_progress integer)
 LANGUAGE sql
AS $function$
	select
		mnemonic_recall.id, lesson_id, lesson_state, lesson_progress
	from
		mnemonic_recall
	where
		mnemonic_recall.account_id = in_account_id
$function$
