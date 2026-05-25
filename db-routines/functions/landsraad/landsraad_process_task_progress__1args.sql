-- landsraad_process_task_progress(max_rows integer) -> void
-- oid: 58432  kind: FUNCTION  category: landsraad

CREATE OR REPLACE FUNCTION dune.landsraad_process_task_progress(max_rows integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	task_progress RECORD = NULL;
	current_term_id BIGINT = NULL;
	last_progress_id BIGINT = NULL;
	old_processed_id BIGINT = NULL;
	new_processed_id BIGINT = NULL;
	new_amount INTEGER = 0;
	player BIGINT = NULL;
	guild BIGINT = NULL;
	notify_guild_ids BIGINT[];
	guild_ids_json JSON = NULL;
BEGIN
	LOCK TABLE landsraad_task_progress_processed IN EXCLUSIVE MODE;

	SELECT term_id FROM landsraad_decree_term ORDER BY start_time DESC LIMIT 1 INTO current_term_id;

	SELECT id FROM landsraad_task_progress ORDER BY id DESC LIMIT 1 INTO last_progress_id;

	SELECT last_processed_id FROM landsraad_task_progress_processed INTO old_processed_id;

	-- read batch of rows sorted by id, process ordered by timestamp
	FOR task_progress IN 
	WITH progress_batch AS (
		SELECT landsraad_task_progress.id, landsraad_task_progress.faction_id, landsraad_task_progress.task_id,
			landsraad_task_progress.faction_progress, landsraad_task_progress.guild_progress, landsraad_task_progress.player_progress, landsraad_task_progress.timestamp, 
			task_progress_players.players, task_progress_guilds.guilds
		FROM landsraad_task_progress,
		LATERAL (SELECT ARRAY_AGG(player_id) AS players FROM landsraad_task_progress_player WHERE landsraad_task_progress_player.progress_id = landsraad_task_progress.id) AS task_progress_players, 
		LATERAL (SELECT ARRAY_AGG(guild_id) AS guilds FROM landsraad_task_progress_guild WHERE landsraad_task_progress_guild.progress_id = landsraad_task_progress.id) AS task_progress_guilds
		WHERE CASE WHEN old_processed_id IS NOT NULL THEN id > old_processed_id ELSE TRUE END
		ORDER BY id LIMIT MAX_ROWS
	)
	SELECT id, faction_id, task_id, players, guilds, faction_progress, guild_progress, player_progress FROM progress_batch ORDER BY timestamp
	LOOP
		IF NOT (SELECT landsraad_has_term_of_task_ended(task_progress.task_id)) THEN
            -- player progress is allowed to happen even if the task was already completed
			IF task_progress.players IS NOT NULL THEN
				FOREACH player IN ARRAY task_progress.players 
				LOOP
					INSERT INTO landsraad_task_player_contributions AS player_contribution (player_id, faction_id, task_id, amount) 
						VALUES (player, task_progress.faction_id, task_progress.task_id, task_progress.player_progress) 
						ON CONFLICT (player_id, faction_id, task_id)
						DO UPDATE SET amount = player_contribution.amount + task_progress.player_progress;
				END LOOP;
			END IF;
            
            IF NOT (SELECT landsraad_task_has_been_completed(task_progress.task_id)) THEN
                IF task_progress.guilds IS NOT NULL THEN
                    FOREACH guild IN ARRAY task_progress.guilds
                    LOOP
                        -- only insert to guild contribution if no vote has been placed
                        IF (SELECT NOT EXISTS (SELECT 1 FROM landsraad_decree_votes WHERE landsraad_decree_votes.guild_id = guild)) THEN
                            INSERT INTO landsraad_task_guild_contributions AS guild_contribution (guild_id, faction_id, task_id, amount) 
                            VALUES (guild, task_progress.faction_id, task_progress.task_id, task_progress.guild_progress) 
                            ON CONFLICT (guild_id, faction_id, task_id)
                            DO UPDATE SET amount = guild_contribution.amount + task_progress.guild_progress;
                            notify_guild_ids = notify_guild_ids || guild;	
                        END IF;
                        
                    END LOOP;
                END IF;

                INSERT INTO landsraad_task_faction_contributions AS faction_contribution (faction_id, task_id, amount) 
                    VALUES (task_progress.faction_id, task_progress.task_id, task_progress.faction_progress) 
                    ON CONFLICT (faction_id, task_id)
                    DO UPDATE SET amount = faction_contribution.amount + task_progress.faction_progress;
            END IF;
		END IF;

		new_processed_id = task_progress.id;
	END LOOP;
	
	IF new_processed_id IS NOT NULL THEN
		IF old_processed_id IS NULL THEN
			INSERT INTO landsraad_task_progress_processed (last_processed_id) VALUES (new_processed_id);
		ELSE
			UPDATE landsraad_task_progress_processed SET last_processed_id = new_processed_id;
		END IF;
	END IF;
	
	IF last_progress_id > new_processed_id THEN
		PERFORM pg_notify('landsraad_notify_channel', format('progress_pressure#{"UnprocessedCount": %s}', last_progress_id - new_processed_id));
	END IF;
	
	IF new_processed_id > old_processed_id THEN
		PERFORM pg_notify('landsraad_notify_channel', 'progress_updated#{"changed": true}');
	ELSE
		PERFORM pg_notify('landsraad_notify_channel', 'progress_updated#{"changed": false}');
	END IF;

    IF cardinality(notify_guild_ids) > 0 THEN
        SELECT json_agg(DISTINCT guild_id) FROM (SELECT unnest(notify_guild_ids) guild_id) guilds INTO guild_ids_json;
        PERFORM pg_notify('landsraad_notify_channel', format('guild_vote_changed#{"GuildIds": %s}', guild_ids_json));
    END IF;

END $function$
