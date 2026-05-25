-- register_temporary_lore_pickup(in_lore_pickup_ids text[]) -> SETOF smallint
-- oid: 58513  kind: FUNCTION  category: server

CREATE OR REPLACE FUNCTION dune.register_temporary_lore_pickup(in_lore_pickup_ids text[])
 RETURNS SETOF smallint
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN query WITH
		input AS (
			SELECT UNNEST (in_lore_pickup_ids) as lore_pickup_id
		),
		existing AS (
			SELECT incremental_id, lore_pickup_id FROM lore_pickups_temporary WHERE lore_pickup_id = ANY(SELECT lore_pickup_id FROM input)
		),
		inserted AS (
			INSERT INTO lore_pickups_temporary("lore_pickup_id") SELECT lore_pickup_id FROM input WHERE NOT lore_pickup_id = ANY(SELECT lore_pickup_id FROM existing) returning incremental_id, lore_pickup_id
		),
		combined AS (
            SELECT incremental_id, lore_pickup_id FROM existing UNION ALL SELECT incremental_id, lore_pickup_id FROM inserted
        )
    SELECT incremental_id FROM combined ORDER BY lore_pickup_id;
END
$function$
