-- delete_mnemonic_recall_lesson(in_account_id bigint, in_lesson_id text) -> void
-- oid: 58227  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.delete_mnemonic_recall_lesson(in_account_id bigint, in_lesson_id text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    DELETE FROM mnemonic_recall WHERE account_id = in_account_id AND lesson_id = in_lesson_id;
END
$function$
