-- landsraad_notify_house_rewards_changed() -> trigger
-- oid: 58429  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_notify_house_rewards_changed()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
	PERFORM pg_notify('landsraad_notify_channel', format('house_rewards_changed#{"PlayerId" : %s}', NEW.player_id));
    RETURN NULL;
END $function$
