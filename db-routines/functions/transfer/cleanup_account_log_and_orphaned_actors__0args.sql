-- cleanup_account_log_and_orphaned_actors() -> void
-- oid: 58171  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune.cleanup_account_log_and_orphaned_actors()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    delete from actors
        WHERE
            -- not is null instead of is not null to match the index expression
            not owner_account_id is null
            AND NOT EXISTS(select 1 from accounts where id=owner_account_id);
    truncate account_removal_log;
END
$function$
