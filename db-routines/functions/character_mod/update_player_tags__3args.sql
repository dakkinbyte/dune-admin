-- update_player_tags(in_account_id bigint, tags_to_add text[], tags_to_remove text[]) -> void
-- oid: 58629  kind: FUNCTION  category: character_mod

CREATE OR REPLACE FUNCTION dune.update_player_tags(in_account_id bigint, tags_to_add text[], tags_to_remove text[])
 RETURNS void
 LANGUAGE sql
AS $function$
    insert into player_tags("account_id", "tag") select in_account_id, unnest(tags_to_add) on conflict do nothing;
    delete from player_tags where account_id = in_account_id and tag = ANY(tags_to_remove);
$function$
