-- clean_old_guild_invites(in_cutoff_timespan bigint) -> void
-- oid: 58167  kind: FUNCTION  category: guild

CREATE OR REPLACE FUNCTION dune.clean_old_guild_invites(in_cutoff_timespan bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DELETE FROM guild_invites WHERE invite_sent_timespan < in_cutoff_timespan;
END
$function$
