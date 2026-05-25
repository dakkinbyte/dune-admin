-- landsraad_load_term_progress(in_term_id bigint, in_num_guilds integer, in_faction_names text[], in_player_ids bigint[]) -> TABLE(faction_progress dune.landsraadtaskfactionprogress[], faction_reveal_state dune.landsraadtaskfactionrevealstate[], guild_contributions dune.landsraadguildcontribution[], player_contributions dune.landsraadplayercontribution[])
-- oid: 58427  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_load_term_progress(in_term_id bigint, in_num_guilds integer, in_faction_names text[], in_player_ids bigint[])
 RETURNS TABLE(faction_progress dune.landsraadtaskfactionprogress[], faction_reveal_state dune.landsraadtaskfactionrevealstate[], guild_contributions dune.landsraadguildcontribution[], player_contributions dune.landsraadplayercontribution[])
 LANGUAGE plpgsql
AS $function$
DECLARE
	term_faction_progress LandsraadTaskFactionProgress[];
	term_faction_reveal_state LandsraadTaskFactionRevealState[];
	term_guild_contributions LandsraadGuildContribution[];
	term_player_contributions LandsraadPlayerContribution[];
BEGIN
	SELECT ARRAY_AGG((task_board_index, faction_name, progress)::LandsraadTaskFactionProgress) FROM landsraad_load_task_faction_progress(in_term_id) INTO term_faction_progress;
	SELECT ARRAY_AGG((task_board_index, faction_name, reveal_state, time_stamp)::LandsraadTaskFactionRevealState) FROM landsraad_load_task_faction_reveal_state(in_term_id) INTO term_faction_reveal_state;
	SELECT ARRAY_AGG((faction_name, guild_name, voting_influence)::LandsraadGuildContribution) FROM landsraad_load_guild_contributions(in_term_id, in_num_guilds, in_faction_names) INTO term_guild_contributions;
	SELECT ARRAY_AGG((player_id, board_index, amount)::LandsraadPlayerContribution) FROM landsraad_load_player_contributions(in_term_id, in_player_ids) INTO term_player_contributions;

	RETURN query SELECT term_faction_progress, term_faction_reveal_state, term_guild_contributions, term_player_contributions;
END $function$
