-- purchase_specialization_keystone(in_player_id bigint, in_keystone text) -> boolean
-- oid: 58501  kind: FUNCTION  category: character_mod

CREATE OR REPLACE FUNCTION dune.purchase_specialization_keystone(in_player_id bigint, in_keystone text)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	found_id SMALLINT;
	inserted_id SMALLINT;
BEGIN
	SELECT id FROM specialization_keystones_map INTO found_id WHERE name = in_keystone;
	IF found_id IS NULL THEN
		RETURN FALSE;
	END IF;
	
	INSERT INTO purchased_specialization_keystones (player_id, keystone_id) VALUES (in_player_id, found_id)
	ON CONFLICT DO NOTHING
	RETURNING keystone_id INTO inserted_id;
	
	IF inserted_id IS NULL THEN
		RETURN FALSE;
	END IF;
	
	RETURN TRUE;
END $function$
