-- delete_mnemonic_recall_lesson_all(in_account_id bigint) -> void
-- oid: 58228  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.delete_mnemonic_recall_lesson_all(in_account_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    DELETE FROM mnemonic_recall WHERE account_id = in_account_id;
END
$function$
