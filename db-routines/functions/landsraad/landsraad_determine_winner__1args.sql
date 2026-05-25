-- landsraad_determine_winner(in_term_id bigint) -> text
-- oid: 58408  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_determine_winner(in_term_id bigint)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
	has_winning_faction BOOLEAN = FALSE;
	winning_faction_name TEXT = NULL;
BEGIN
	SELECT CASE WHEN winning_faction_id IS NULL THEN FALSE ELSE TRUE END FROM landsraad_decree_term WHERE term_id = in_term_id INTO has_winning_faction;
	
	-- only set winning faction if not set already (sysselraad has been secured)
	IF NOT has_winning_faction THEN
		WITH tasks_completed_by_faction AS (SELECT winning_faction_id AS faction, COUNT(id) AS num_tasks FROM landsraad_tasks WHERE term_id = in_term_id AND winning_faction_id IS NOT NULL GROUP BY (winning_faction_id)),
			winner_count AS (SELECT COUNT(faction) AS amount FROM tasks_completed_by_faction WHERE num_tasks = (SELECT MAX(num_tasks) FROM tasks_completed_by_faction) GROUP BY(num_tasks)),
			winner AS (SELECT faction FROM tasks_completed_by_faction ORDER BY num_tasks DESC LIMIT 1)
		UPDATE landsraad_decree_term SET winning_faction_id = CASE WHEN winner_count.amount = 1 THEN winner.faction ELSE NULL END FROM winner, winner_count;
		PERFORM pg_notify('landsraad_notify_channel', 'state_changed');
	END IF;

	SELECT factions.name FROM landsraad_decree_term AS term LEFT JOIN factions ON term.winning_faction_id = factions.id WHERE term.term_id = in_term_id INTO winning_faction_name;
	
	RETURN winning_faction_name;
END $function$
