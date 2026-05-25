-- landsraad_collect_votes(in_term_id bigint) -> TABLE(elected_decree text, winning_faction_name text, available_decrees text[], guild_votes dune.landsraadguildvotetelemetry[])
-- oid: 58407  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_collect_votes(in_term_id bigint)
 RETURNS TABLE(elected_decree text, winning_faction_name text, available_decrees text[], guild_votes dune.landsraadguildvotetelemetry[])
 LANGUAGE plpgsql
AS $function$
DECLARE
	has_elected_decree BOOL = FALSE;
	has_winning_faction BOOL = FALSE;
	winning_decree_id BIGINT = NULL;
    winning_decree_name TEXT = NULL;
	winning_faction_name TEXT = NULL;
    winning_faction_id INT = NULL;
	available_decrees TEXT[];
    vote_telemetry LandsraadGuildVoteTelemetry[];
BEGIN
	LOCK TABLE landsraad_decree_term, landsraad_decree_rotation, landsraad_decree_votes IN EXCLUSIVE MODE;

	SELECT CASE WHEN landsraad_decree_term.elected_decree_id IS NULL THEN FALSE ELSE TRUE END, 
		   CASE WHEN landsraad_decree_term.winning_faction_id IS NULL THEN FALSE ELSE TRUE END
		FROM landsraad_decree_term WHERE term_id = in_term_id INTO has_elected_decree, has_winning_faction;
		
	IF has_winning_faction IS FALSE THEN
		RETURN query SELECT NULL, NULL, available_decrees, vote_telemetry;
		RETURN;
	END IF;
	
	SELECT factions.name, term.winning_faction_id FROM landsraad_decree_term AS term LEFT JOIN factions ON term.winning_faction_id = factions.id WHERE term.term_id = in_term_id INTO winning_faction_name, winning_faction_id;

	SELECT ARRAY_AGG(landsraad_decrees.decree_name) FROM landsraad_decree_rotation INNER JOIN landsraad_decrees ON landsraad_decree_rotation.decree_id = landsraad_decrees.id INTO available_decrees;
	
	SELECT ARRAY_AGG((guild_id, decree_name, voting_influence)::LandsraadGuildVoteTelemetry) FROM landsraad_collect_vote_telemetry(in_term_id, winning_faction_id) INTO vote_telemetry;

	-- Only resolve votes if the latest term has no elected decree
	IF has_elected_decree IS FALSE THEN
		WITH
			votes AS (SELECT decree_id, SUM(influence) AS amount FROM landsraad_decree_votes GROUP BY decree_id), 
			max_votes AS (SELECT MAX(amount) AS amount FROM votes)
		UPDATE landsraad_decree_term
			SET elected_decree_id = 
				CASE WHEN (SELECT amount FROM max_votes) IS NOT NULL THEN
					(SELECT decree_id FROM votes WHERE amount = (SELECT amount FROM max_votes) ORDER BY RANDOM() LIMIT 1)
				ELSE
					(SELECT decree_id FROM landsraad_decree_rotation ORDER BY RANDOM() LIMIT 1)
				END
			WHERE term_id = in_term_id
			returning elected_decree_id INTO winning_decree_id;
	ELSE
		SELECT term.elected_decree_id FROM landsraad_decree_term term ORDER BY term_id DESC LIMIT 1 INTO winning_decree_id;
	END IF;

	SELECT decree_name FROM landsraad_decrees WHERE id = winning_decree_id INTO winning_decree_name;
	
	RETURN query SELECT winning_decree_name, winning_faction_name, available_decrees, vote_telemetry;
END $function$
