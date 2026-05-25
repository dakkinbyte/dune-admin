-- fix_broken_harkonnen_players_due_to_fooled_thufir() -> void
-- oid: 58264  kind: FUNCTION  category: misc

CREATE OR REPLACE FUNCTION dune.fix_broken_harkonnen_players_due_to_fooled_thufir()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN

    -- Dropping tables due to them being created in temp_backup_tables.sql
    drop table if exists da_6358_pre_broken_players;
    drop table if exists da_6358_broken_players_12400;
    drop table if exists da_6358_broken_players_1300;

---Fix players that are in a broken state but haven't been blocked yet
--Tag combo to check for:
--DialogueFlags.Factions.Hark_ThufirBetrayedComplete
--DialogueFlags.Faction.FooledThufir
--PlayerIsFactionTier Harkonnen 5
--TO FIX:
--Remove DialogueFlags.Faction.FooledThufir
    create table if not exists da_6358_pre_broken_players as
    select pt.account_id from player_tags pt
    group by pt.account_id
    HAVING array_agg(DISTINCT tag) @> ARRAY['DialogueFlags.Factions.Hark_ThufirBetrayedComplete', 'DialogueFlags.Faction.FooledThufir', 'Faction.Harkonnen.Tier5'];

    delete from player_tags pt using da_6358_pre_broken_players where pt.account_id = da_6358_pre_broken_players.account_id and pt.tag = 'DialogueFlags.Faction.FooledThufir';

---Fix players that are in a broken state since 1.2.40
---Tag combo to check for:
---DialogueFlags.Factions.Hark_ThufirBetrayedComplete
---DialogueFlags.Faction.FooledThufir
---Contract.Tracking.FactionStory.R4C6Completed
---PlayerIsFactionTier Harkonnen 4
---TO FIX:
---Remove DialogueFlags.Faction.FooledThufir
---Promote player to Harkonnen 5

    create table if not exists da_6358_broken_players_12400 as
    with broken_accounts as (
        select pt.account_id
        from player_tags pt
        group by pt.account_id
        having array_agg(distinct pt.tag) @> array[
            'DialogueFlags.Factions.Hark_ThufirBetrayedComplete',
            'DialogueFlags.Faction.FooledThufir',
            'Contract.Tracking.FactionStory.R4C6Completed',
            'Faction.Harkonnen.Tier4'
            ]
           and not array_agg(distinct pt.tag) && array['Faction.Harkonnen.Tier5']
    ),
    one_state_row_per_account as (
        -- If player_state can theoretically have duplicates per account_id,
        -- pick one deterministically.
        select distinct on (ps.account_id)
             ps.account_id,
             ps.player_controller_id
         from player_state ps
                  join broken_accounts ba on ba.account_id = ps.account_id
         order by ps.account_id, ps.player_controller_id desc
    )
    select
        s.account_id,
        s.player_controller_id,
        a.properties as backup_properties
    from one_state_row_per_account s
             join actors a on a.id = s.player_controller_id;

    INSERT INTO player_tags (account_id, tag)
    SELECT account_id, 'Faction.Harkonnen.Tier5' as tag
    FROM da_6358_broken_players_12400
    ON CONFLICT (account_id, tag) DO NOTHING;

    delete from player_tags pt using da_6358_broken_players_12400 where pt.account_id = da_6358_broken_players_12400.account_id and pt.tag = 'DialogueFlags.Faction.FooledThufir';
    UPDATE actors
    SET properties = jsonb_set(
        properties,
        '{FactionPlayerComponent,m_FactionDataArray}',
        (
            SELECT coalesce(
                       jsonb_agg(
                           CASE
                               WHEN elem->'Faction'->>'Name' = 'Harkonnen'
                                   THEN jsonb_set(elem, '{ReputationAmount}', '2000'::jsonb)
                               ELSE elem
                               END
                       ),
                       '[]'::jsonb
                   )
            FROM jsonb_array_elements(properties->'FactionPlayerComponent'->'m_FactionDataArray') AS t(elem)
        )
    )
    FROM da_6358_broken_players_12400 b12400
    WHERE b12400.player_controller_id = actors.id;

---Fix players that are in a broken state in live aka 1.3.0
---Tag combo to check for:
---DialogueFlags.Factions.Hark_ThufirBetrayedComplete
---Contract.Tracking.FactionStory.R4C6Completed
---PlayerIsFactionTier Harkonnen 4
---NOT DialogueFlags.Faction.FooledThufir
    create table if not exists da_6358_broken_players_1300 as
    with broken_accounts as (
        select pt.account_id
        from player_tags pt
        group by pt.account_id
        HAVING array_agg(DISTINCT tag) @> ARRAY ['DialogueFlags.Factions.Hark_ThufirBetrayedComplete', 'Contract.Tracking.FactionStory.R4C6Completed', 'Faction.Harkonnen.Tier4']
           and not array_agg(distinct tag) && array['DialogueFlags.Faction.FooledThufir', 'Faction.Harkonnen.Tier5'] -- Since Tier4 players can also have Tier5 we need to exclude that
    ),
         one_state_row_per_account as (
             -- If player_state can theoretically have duplicates per account_id,
             -- pick one deterministically.
             select distinct on (ps.account_id)
                 ps.account_id,
                 ps.player_controller_id
             from player_state ps
                      join broken_accounts ba on ba.account_id = ps.account_id
             order by ps.account_id, ps.player_controller_id desc
         )
    select
        s.account_id,
        s.player_controller_id,
        a.properties as backup_properties
    from one_state_row_per_account s
             join actors a on a.id = s.player_controller_id;

    INSERT INTO player_tags (account_id, tag)
    SELECT account_id, 'Faction.Harkonnen.Tier5' as tag
    FROM da_6358_broken_players_1300
    ON CONFLICT (account_id, tag) DO NOTHING;

    UPDATE actors
    SET properties = jsonb_set(
        properties,
        '{FactionPlayerComponent,m_FactionDataArray}',
        (
            SELECT coalesce(
                       jsonb_agg(
                           CASE
                               WHEN elem->'Faction'->>'Name' = 'Harkonnen'
                                   THEN jsonb_set(elem, '{ReputationAmount}', '2000'::jsonb)
                               ELSE elem
                               END
                       ),
                       '[]'::jsonb
                   )
            FROM jsonb_array_elements(properties->'FactionPlayerComponent'->'m_FactionDataArray') AS t(elem)
        )
                     )
    FROM da_6358_broken_players_1300 b1300
    WHERE b1300.player_controller_id = actors.id;
END;
$function$
