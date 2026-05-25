-- can_takeover_account(in_user_id text) -> boolean
-- oid: 58156  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune.can_takeover_account(in_user_id text)
 RETURNS boolean
 LANGUAGE sql
AS $function$
    select takeoverable from accounts WHERE "user" = in_user_id;
$function$
