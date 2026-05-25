-- is_player_guild_admin(in_player_id bigint, in_guild_id bigint) -> boolean
-- oid: 58393  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.is_player_guild_admin(in_player_id bigint, in_guild_id bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	found_role_id SMALLINT;
BEGIN
	SELECT role_id FROM guild_members WHERE player_id = in_player_id AND guild_id = in_guild_id INTO found_role_id;
	IF NOT FOUND THEN
    	RETURN FALSE;
	END IF;
	RETURN found_role_id = 100;
END
$function$
