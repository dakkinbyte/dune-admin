-- update_consumed_per_player_lore(in_actor_id bigint, in_consumed_bit_array bit, in_use_temporary boolean) -> void
-- oid: 58617  kind: FUNCTION  category: misc

CREATE OR REPLACE FUNCTION dune.update_consumed_per_player_lore(in_actor_id bigint, in_consumed_bit_array bit, in_use_temporary boolean)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	IF in_use_temporary THEN
    	INSERT INTO consumed_temporary_per_player_lore(actor_id, consumed_bit_array)
    	VALUES(in_actor_id, in_consumed_bit_array)
    	ON CONFLICT (actor_id)
    	DO UPDATE SET
        	consumed_bit_array = in_consumed_bit_array;
	ELSE
    	INSERT INTO consumed_per_player_lore(actor_id, consumed_bit_array)
    	VALUES(in_actor_id, in_consumed_bit_array)
    	ON CONFLICT (actor_id)
    	DO UPDATE SET
        	consumed_bit_array = in_consumed_bit_array;
	END IF;
END; $function$
