-- landsraad_load_house_rewards(in_player_id bigint) -> TABLE(house_name text, template_id text, amount integer, last_updated timestamp without time zone)
-- oid: 58423  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_load_house_rewards(in_player_id bigint)
 RETURNS TABLE(house_name text, template_id text, amount integer, last_updated timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN query (SELECT rewards.house_name, rewards.template_id, rewards.amount, (rewards.last_updated AT TIME ZONE 'UTC')::TIMESTAMP FROM landsraad_house_rewards AS rewards WHERE player_id = in_player_id AND rewards.amount > 0);
END $function$
