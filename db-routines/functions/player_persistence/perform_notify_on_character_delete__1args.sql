-- perform_notify_on_character_delete(in_user_id text) -> void
-- oid: 58484  kind: FUNCTION  category: player_persistence

CREATE OR REPLACE FUNCTION dune.perform_notify_on_character_delete(in_user_id text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	PERFORM pg_notify('player_info_notify_channel', format('character_deleted#%s', in_user_id));
END
$function$
