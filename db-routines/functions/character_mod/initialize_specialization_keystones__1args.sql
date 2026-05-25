-- initialize_specialization_keystones(in_keystones text[]) -> TABLE(keystone_id smallint, keystone_name text)
-- oid: 58388  kind: FUNCTION  category: character_mod

CREATE OR REPLACE FUNCTION dune.initialize_specialization_keystones(in_keystones text[])
 RETURNS TABLE(keystone_id smallint, keystone_name text)
 LANGUAGE plpgsql
AS $function$
BEGIN
	LOCK TABLE specialization_keystones_map IN SHARE ROW EXCLUSIVE MODE;

-- Note: we filter the existing values before the insert, otherwise it bumps the generated id in specialization_keystones_map 
	INSERT INTO specialization_keystones_map (name)
		SELECT in_keystone_name FROM UNNEST(in_keystones) in_keystone_name LEFT JOIN specialization_keystones_map k ON in_keystone_name = k.name
		WHERE name IS NULL;
	RETURN QUERY SELECT * from specialization_keystones_map;
END $function$
