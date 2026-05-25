-- update_specialization_refund_id(in_player_id bigint, in_refund_id smallint, in_removed_keystones smallint[]) -> void
-- oid: 58638  kind: FUNCTION  category: character_mod

CREATE OR REPLACE FUNCTION dune.update_specialization_refund_id(in_player_id bigint, in_refund_id smallint, in_removed_keystones smallint[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM purchased_specialization_keystones WHERE player_id = in_player_id AND keystone_id = ANY(in_removed_keystones);

	INSERT INTO specialization_refund_id (player_id, refund_id) VALUES(in_player_id, in_refund_id)
	ON conflict (player_id) DO UPDATE SET refund_id = in_refund_id;
END $function$
