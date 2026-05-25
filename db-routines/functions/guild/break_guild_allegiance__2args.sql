-- break_guild_allegiance(in_guild_id bigint, in_neutral_faction_id smallint) -> void
-- oid: 58155  kind: FUNCTION  category: guild

CREATE OR REPLACE FUNCTION dune.break_guild_allegiance(in_guild_id bigint, in_neutral_faction_id smallint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	guild_data_record record;
BEGIN
	PERFORM guilds_get_exclusive_operation_lock();

	SELECT * INTO guild_data_record FROM guilds WHERE guild_id = in_guild_id;
	IF guild_data_record IS NULL THEN
		RAISE EXCEPTION 'Trying to break guild allegiance of a non existing guild: %', in_guild_id;
	END IF;

	if guild_data_record.guild_faction = in_neutral_faction_id THEN
		RAISE EXCEPTION 'Guild already has neutral faction';
	END IF;

	UPDATE guilds SET guild_faction = in_neutral_faction_id WHERE guilds.guild_id = in_guild_id;

	PERFORM pg_notify('guild_notify_channel', format('break_guild_allegiance#{"GuildId" : %s , "OldGuildFactionDbId" : %s, "NewGuildFactionDbId" : %s}', in_guild_id, guild_data_record.guild_faction, in_neutral_faction_id));
END
$function$
