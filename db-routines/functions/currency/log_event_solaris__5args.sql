-- log_event_solaris(in_function_oid oid, in_message dune.logmessagetype, in_controller_id bigint, in_solaris_balance bigint, in_solaris_delta bigint) -> void
-- oid: 58470  kind: FUNCTION  category: currency

CREATE OR REPLACE FUNCTION dune.log_event_solaris(in_function_oid oid, in_message dune.logmessagetype, in_controller_id bigint, in_solaris_balance bigint, in_solaris_delta bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    partition_id BIGINT = 0;
	calling_function_name LogFunctionType;
	fls_id TEXT;
	fc_id BYTEA;
	char_name BYTEA;
BEGIN

    partition_id := coalesce(current_setting('dune.partition_id', true)::BIGINT, 0);

	-- map calling function name to LogFunctionType (each calling function must be added to LogFunctionType)
	SELECT proname::text::LogFunctionType
		INTO calling_function_name
		FROM pg_proc
		WHERE oid = in_function_oid;
	
	-- get the fls_id for the user performing the acction
	SELECT acc."user"
		INTO fls_id
		FROM accounts acc
		JOIN player_state ps on ps.account_id = acc.id
		WHERE ps.player_controller_id = in_controller_id
		LIMIT 1;

    INSERT INTO event_log (
        partition_id,
        category,
		function_name,
        message,
        event_time,
        meta
    ) VALUES (
        partition_id,
        'solaris',
		calling_function_name,
        in_message,
        now(),
        json_build_object('fls_id', fls_id, 'event', calling_function_name::text, 'solaris_balance', in_solaris_balance, 'solaris_delta', in_solaris_delta)
    );
END;
$function$
