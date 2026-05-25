-- admin_read_player_tags(in_account_id bigint) -> TABLE(tags text)
-- oid: 58138  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.admin_read_player_tags(in_account_id bigint)
 RETURNS TABLE(tags text)
 LANGUAGE sql
AS $function$
	select
		pt.tag
	from
		player_tags as pt
	where
		pt.account_id = in_account_id
$function$
