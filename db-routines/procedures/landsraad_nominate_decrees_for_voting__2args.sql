-- landsraad_nominate_decrees_for_voting(IN last_active_decree_id bigint, IN num_decrees integer) -> void
-- oid: 58428  kind: PROCEDURE  category: landsraad

CREATE OR REPLACE PROCEDURE dune.landsraad_nominate_decrees_for_voting(IN last_active_decree_id bigint, IN num_decrees integer)
 LANGUAGE plpgsql
AS $procedure$
BEGIN
	LOCK TABLE landsraad_decrees, landsraad_decree_rotation, landsraad_decree_votes IN EXCLUSIVE MODE;
	
	TRUNCATE TABLE landsraad_decree_votes;
	TRUNCATE TABLE landsraad_decree_rotation;

	INSERT INTO landsraad_decree_rotation
		SELECT id FROM landsraad_decrees
		WHERE (
			CASE WHEN last_active_decree_id IS NULL THEN
				True
			ELSE
				last_active_decree_id != id
			END
		) AND disabled = FALSE
		ORDER BY RANDOM() * weight DESC
		LIMIT num_decrees;
END $procedure$
