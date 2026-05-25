-- get_guild_for_player(in_player_id bigint) -> bigint
-- oid: 58309  kind: FUNCTION  category: guild

CREATE OR REPLACE FUNCTION dune.get_guild_for_player(in_player_id bigint)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	found_guild_id integer;
BEGIN
	SELECT guild_id FROM guild_members WHERE player_id = in_player_id INTO found_guild_id;
	IF NOT FOUND THEN
    	RETURN 0;
	END IF;
	RETURN found_guild_id;
END
$function$
