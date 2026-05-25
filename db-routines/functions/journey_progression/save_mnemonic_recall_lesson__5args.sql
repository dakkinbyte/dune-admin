-- save_mnemonic_recall_lesson(in_account_id bigint, in_lesson_id text, in_lesson_state bigint, in_lesson_progress integer, in_is_new boolean) -> void
-- oid: 58552  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.save_mnemonic_recall_lesson(in_account_id bigint, in_lesson_id text, in_lesson_state bigint, in_lesson_progress integer, in_is_new boolean)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO mnemonic_recall(account_id, lesson_id, lesson_state, lesson_progress, is_new)
    VALUES(in_account_id, in_lesson_id, in_lesson_state, in_lesson_progress, in_is_new)
    ON CONFLICT (account_id, lesson_id)
    DO UPDATE SET
        lesson_state = in_lesson_state,
        lesson_progress = in_lesson_progress,
        is_new = in_is_new;
END; $function$
