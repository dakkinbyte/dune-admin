-- get_unsaved_base_totem_ids_for_account(in_account_id bigint) -> TABLE(totem_id bigint)
-- oid: 58363  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune.get_unsaved_base_totem_ids_for_account(in_account_id bigint)
 RETURNS TABLE(totem_id bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
		SELECT t.id
		FROM totems t
		JOIN permission_actor_rank par ON t.id = par.permission_actor_id
		JOIN player_state ps ON par.player_id = ps.player_controller_id
		LEFT JOIN base_backup_linked_actors bbla ON t.id = bbla.actor_id
		WHERE ps.account_id = in_account_id
			AND bbla.actor_id IS NULL;
END
$function$
