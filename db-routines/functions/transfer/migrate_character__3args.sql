-- migrate_character(in_account_id bigint, home_dimension integer, max_solaris_allowed bigint) -> void
-- oid: 58476  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune.migrate_character(in_account_id bigint, home_dimension integer, max_solaris_allowed bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    controller_id BIGINT;
    pawn_id BIGINT;
BEGIN
    SELECT player_controller_id, player_pawn_id into controller_id, pawn_id
    FROM player_state ps
    WHERE ps.account_id = in_account_id;

    UPDATE encrypted_player_state SET home_dimension_index = home_dimension WHERE account_id = in_account_id;

	UPDATE demo_users
	SET demo_state = 'DbMigratedToRetail'::DemoState, demo_playtime_seconds = NULL
    WHERE fls_id = (
		SELECT acc.user FROM accounts AS acc WHERE acc.id = in_account_id
		);

    PERFORM migrate_clamp_max_allow_solaris(pawn_id, max_solaris_allowed);
END
$function$
