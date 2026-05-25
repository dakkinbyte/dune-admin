-- landsraad_withdraw_house_reward(in_player_id bigint, in_house_rewards dune.landsraadplayerhousereward[]) -> void
-- oid: 58437  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_withdraw_house_reward(in_player_id bigint, in_house_rewards dune.landsraadplayerhousereward[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	current_amount INTEGER = NULL;
	house_reward record = NULL;
    grouped_house_rewards LandsraadPlayerHouseReward[];
BEGIN
	LOCK TABLE landsraad_house_rewards IN EXCLUSIVE MODE;
    --group rewards to make sure multiple entries of the same item do not slip by amount verfication below
    WITH grouped_rewards AS (SELECT house_name, template_id, SUM(amount) as amount FROM UNNEST(in_house_rewards) GROUP BY house_name, template_id)
        SELECT ARRAY_AGG((grouped_rewards.house_name, grouped_rewards.template_id, grouped_rewards.amount)::LandsraadPlayerHouseReward) INTO grouped_house_rewards FROM grouped_rewards;
    
	FOREACH house_reward in ARRAY grouped_house_rewards
	LOOP
		SELECT lhr.amount INTO current_amount FROM landsraad_house_rewards AS lhr WHERE lhr.player_id = in_player_id AND lhr.house_name = house_reward.house_name AND lhr.template_id = house_reward.template_id;

		IF current_amount IS NULL OR current_amount < house_reward.amount THEN
			RAISE EXCEPTION 'Cannot withdraw house reward %s for player % and house %s', house_reward.template_id, in_player_id, house_reward.house_name;
			RETURN;
		END IF;
	END LOOP;
	-- finish full loop of checks first, all rewards need to be withdrawable before updating
	FOREACH house_reward in ARRAY grouped_house_rewards
	LOOP
		UPDATE landsraad_house_rewards SET amount = amount - house_reward.amount, last_updated = CURRENT_TIMESTAMP WHERE player_id = in_player_id AND house_name = house_reward.house_name AND template_id = house_reward.template_id;
	END LOOP;
END $function$
