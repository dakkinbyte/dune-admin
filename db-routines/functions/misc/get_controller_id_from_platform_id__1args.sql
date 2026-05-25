-- get_controller_id_from_platform_id(in_platform_id text) -> bigint
-- oid: 58295  kind: FUNCTION  category: misc

CREATE OR REPLACE FUNCTION dune.get_controller_id_from_platform_id(in_platform_id text)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
    out_controller_id BIGINT;
BEGIN
    SELECT ps.player_controller_id
    INTO out_controller_id
    FROM accounts acc LEFT JOIN player_state ps ON acc.id=ps.account_id
    WHERE acc.platform_id = in_platform_id
    LIMIT 1;
    RETURN out_controller_id;
END
$function$
