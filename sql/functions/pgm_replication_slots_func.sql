CREATE FUNCTION @extschema@.pgm_replication_slots_func() RETURNS TABLE
(
    slot_name name
    , active int
    , retained_bytes numeric
    , database name
    , slot_type text
    , conflicting int
    , failover int
    , synced int
)
    LANGUAGE plpgsql
AS $function$
DECLARE
BEGIN

IF current_setting('server_version_num')::int >= 170000 THEN

    RETURN QUERY
    SELECT s.slot_name
        , s.active::int
        , pg_wal_lsn_diff(CASE WHEN pg_is_in_recovery() THEN pg_last_wal_replay_lsn() ELSE pg_current_wal_insert_lsn() END, s.restart_lsn) AS retained_bytes
        , s.database
        , s.slot_type
        , s.conflicting::int
        , s.failover::int
        , s.synced::int
    FROM pg_catalog.pg_replication_slots s;

ELSIF current_setting('server_version_num')::int >= 160000  AND current_setting('server_version_num')::int < 170000 THEN

    RETURN QUERY
    SELECT s.slot_name
        , s.active::int
        , pg_wal_lsn_diff(CASE WHEN pg_is_in_recovery() THEN pg_last_wal_replay_lsn() ELSE pg_current_wal_insert_lsn() END, s.restart_lsn) AS retained_bytes
        , s.database
        , s.slot_type
        , s.conflicting::int
        , 0 AS failover
        , 0 AS synced
    FROM pg_catalog.pg_replication_slots s;

ELSE

    RETURN QUERY
    SELECT s.slot_name
        , s.active::int
        , pg_wal_lsn_diff(CASE WHEN pg_is_in_recovery() THEN pg_last_wal_replay_lsn() ELSE pg_current_wal_insert_lsn() END, s.restart_lsn) AS retained_bytes
        , s.database
        , s.slot_type
        , 0 AS conflicting
        , 0 AS failover
        , 0 AS synced
    FROM pg_catalog.pg_replication_slots s;

END IF;

END
$function$;
