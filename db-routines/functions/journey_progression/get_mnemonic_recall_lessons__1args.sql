-- get_mnemonic_recall_lessons(in_account_id bigint) -> TABLE(id bigint, lesson_id text, lession_state bigint, lesson_progress integer, is_new boolean)
-- oid: 58320  kind: FUNCTION  category: journey_progression

CREATE OR REPLACE FUNCTION dune.get_mnemonic_recall_lessons(in_account_id bigint)
 RETURNS TABLE(id bigint, lesson_id text, lession_state bigint, lesson_progress integer, is_new boolean)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT t.id, t.lesson_id, t.lesson_state, t.lesson_progress, t.is_new
    FROM mnemonic_recall as t
    WHERE t.account_id = in_account_id
    ORDER BY t.id;
END; $function$
