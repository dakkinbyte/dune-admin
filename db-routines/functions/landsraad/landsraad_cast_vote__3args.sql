-- landsraad_cast_vote(in_term_id bigint, in_player_id bigint, in_decree_name text) -> void
-- oid: 58399  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_cast_vote(in_term_id bigint, in_player_id bigint, in_decree_name text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	term_winning_faction_id SMALLINT = NULL;
	elected_decree_id BIGINT = NULL;
	player_guild_id BIGINT = NULL;
	guild_faction_id SMALLINT = NULL;
	voting_decree_id BIGINT = NULL;
	voting_influence INTEGER = 0;
	guild_ids_json JSON = NULL;
BEGIN
	LOCK TABLE landsraad_decree_votes IN EXCLUSIVE MODE;

	SELECT term.winning_faction_id, term.elected_decree_id FROM landsraad_decree_term AS term WHERE term.term_id = in_term_id INTO term_winning_faction_id, elected_decree_id;

	IF term_winning_faction_id IS NULL THEN
		RAISE EXCEPTION 'Cannot insert landsraad vote, term % has no winning faction yet', in_term_id;
	END IF;

	IF elected_decree_id IS NOT NULL THEN
		RAISE EXCEPTION 'Cannot insert landsraad vote, term % already has an elected decree', in_term_id;
	END IF;

	SELECT guilds.guild_id, guilds.guild_faction FROM guild_members 
		JOIN guilds ON guild_members.guild_id = guilds.guild_id WHERE guild_members.player_id = in_player_id INTO player_guild_id, guild_faction_id;

	IF player_guild_id IS NULL THEN
		RAISE EXCEPTION 'Cannot insert landsraad vote, player % not in guild', in_player_id;
	END IF;

	IF guild_faction_id != term_winning_faction_id THEN
		RAISE EXCEPTION 'Cannot insert landsraad vote, guild % not alligned to winning faction %', player_guild_id, term_winning_faction_id;
	END IF;

	IF is_player_guild_admin(in_player_id, player_guild_id) = FALSE THEN
		RAISE EXCEPTION 'Cannot insert landsraad vote, player % is not guild admin of guild %', in_player_id, player_guild_id;
	END IF;

	IF EXISTS (SELECT FROM landsraad_decree_votes AS votes WHERE votes.guild_id = player_guild_id) THEN
		RAISE WARNING 'Cannot insert landsraad vote, guild % has voted already', player_guild_id;
		RETURN;
	END IF;

	SELECT decrees.id FROM landsraad_decree_rotation AS rotation 
		INNER JOIN landsraad_decrees AS decrees ON rotation.decree_id = decrees.id
		WHERE decrees.decree_name = in_decree_name INTO voting_decree_id;

	IF voting_decree_id IS NULL THEN
		RAISE EXCEPTION 'Cannot insert landsraad vote, decree % not for election', in_decree_name;
	END IF;

	SELECT FLOOR(landsraad_load_guild_contribution(in_term_id, player_guild_id, term_winning_faction_id))::INTEGER INTO voting_influence;

	IF voting_influence IS NULL THEN
		RAISE WARNING 'Cannot insert landsraad vote, guild % has no contribution', player_guild_id;
		RETURN;
	END IF;

	INSERT INTO landsraad_decree_votes VALUES(voting_decree_id, player_guild_id, in_player_id, voting_influence);

	SELECT json_agg(player_guild_id) INTO guild_ids_json;
	PERFORM pg_notify('landsraad_notify_channel', format('guild_vote_changed#{"GuildIds": %s}', guild_ids_json));

END $function$
