
/**** metric views ****/
CREATE VIEW @extschema@.ccp_pg_is_in_recovery AS
    SELECT CASE WHEN pg_is_in_recovery = true THEN 1 ELSE 2 END AS status from pg_is_in_recovery();
INSERT INTO @extschema@.metric_views (
    view_name
    , materialized_view
    , scope )
VALUES (
   'ccp_pg_is_in_recovery'
    , false
    , 'global');


CREATE VIEW @extschema@.ccp_postgresql_version AS
    SELECT current_setting('server_version_num')::int AS current;
INSERT INTO @extschema@.metric_views (
    view_name
    , materialized_view
    , scope )
VALUES (
   'ccp_postgresql_version'
    , false
    , 'global');


CREATE VIEW @extschema@.ccp_postmaster_runtime AS
    SELECT extract('epoch' from pg_postmaster_start_time) AS start_time_seconds
    FROM pg_catalog.pg_postmaster_start_time();
INSERT INTO @extschema@.metric_views (
    view_name
    , materialized_view
    , scope )
VALUES (
   'ccp_postmaster_runtime'
    , false
    , 'global');

-- Did not make as a matview since this is a critical metric to always be sure is current
CREATE VIEW @extschema@.ccp_transaction_wraparound AS
    WITH max_age AS (
        SELECT 2000000000 as max_old_xid
        , setting AS autovacuum_freeze_max_age
        FROM pg_catalog.pg_settings
        WHERE name = 'autovacuum_freeze_max_age')
    , per_database_stats AS (
        SELECT datname
        , m.max_old_xid::int
        , m.autovacuum_freeze_max_age::int
        , age(d.datfrozenxid) AS oldest_current_xid
        FROM pg_catalog.pg_database d
        JOIN max_age m ON (true)
        WHERE d.datallowconn)
    SELECT max(oldest_current_xid) AS oldest_current_xid
    , max(ROUND(100*(oldest_current_xid/max_old_xid::float))) AS percent_towards_wraparound
    , max(ROUND(100*(oldest_current_xid/autovacuum_freeze_max_age::float))) AS percent_towards_emergency_autovac
    FROM per_database_stats;
INSERT INTO @extschema@.metric_views (
    view_name
    , materialized_view
    , scope )
VALUES (
   'ccp_transaction_wraparound'
    , false
    , 'global');


-- Did not make as a matview since this is a critical metric to always be sure is current
CREATE VIEW @extschema@.ccp_archive_command_status AS
    SELECT CASE
        WHEN EXTRACT(epoch from (last_failed_time - last_archived_time)) IS NULL THEN 0
        WHEN EXTRACT(epoch from (last_failed_time - last_archived_time)) < 0 THEN 0
        ELSE EXTRACT(epoch from (last_failed_time - last_archived_time))
        END AS seconds_since_last_fail
    , EXTRACT(epoch from (CURRENT_TIMESTAMP - last_archived_time)) AS seconds_since_last_archive
    , archived_count
    , failed_count
    FROM pg_catalog.pg_stat_archiver;
INSERT INTO @extschema@.metric_views (
    view_name
    , materialized_view
    , scope )
VALUES (
   'ccp_archive_command_status'
    , false
    , 'global');


CREATE VIEW @extschema@.ccp_postmaster_uptime AS
    SELECT extract(epoch from (clock_timestamp() - pg_postmaster_start_time() )) AS seconds;
INSERT INTO @extschema@.metric_views (
    view_name
    , materialized_view
    , scope )
VALUES (
   'ccp_postmaster_uptime'
    , false
    , 'global');


CREATE VIEW @extschema@.ccp_settings_pending_restart AS
    SELECT count(*) AS count FROM pg_catalog.pg_settings WHERE pending_restart = true;
INSERT INTO @extschema@.metric_views (
    view_name
    , materialized_view
    , scope )
VALUES (
   'ccp_settings_pending_restart'
    , false
    , 'global');

-- Must be able to get replica stats, so cannot be matview
CREATE VIEW @extschema@.ccp_replication_lag AS
    SELECT
       CASE
       WHEN (pg_last_wal_receive_lsn() = pg_last_wal_replay_lsn()) OR (pg_is_in_recovery() = false) THEN 0
       ELSE EXTRACT (EPOCH FROM clock_timestamp() - pg_last_xact_replay_timestamp())::INTEGER
       END
    AS replay_time
    ,  CASE
       WHEN pg_is_in_recovery() = false THEN 0
       ELSE EXTRACT (EPOCH FROM clock_timestamp() - pg_last_xact_replay_timestamp())::INTEGER
       END
    AS received_time;
INSERT INTO @extschema@.metric_views (
    view_name
    , materialized_view
    , scope )
VALUES (
   'ccp_replication_lag'
    , false
    , 'global');


-- Must be able to get replica stats, so cannot be matview
CREATE VIEW @extschema@.ccp_connection_stats AS
    SELECT ((total - idle) - idle_in_txn) as active
        , total
        , idle
        , idle_in_txn
        , (SELECT COALESCE(EXTRACT(epoch FROM (MAX(clock_timestamp() - state_change))),0) FROM pg_catalog.pg_stat_activity WHERE state = 'idle in transaction') AS max_idle_in_txn_time
        , (SELECT COALESCE(EXTRACT(epoch FROM (MAX(clock_timestamp() - query_start))),0) FROM pg_catalog.pg_stat_activity WHERE backend_type = 'client backend' AND state <> 'idle' ) AS max_query_time
        , (SELECT COALESCE(EXTRACT(epoch FROM (MAX(clock_timestamp() - query_start))),0) FROM pg_catalog.pg_stat_activity WHERE backend_type = 'client backend' AND wait_event_type = 'Lock' ) AS max_blocked_query_time
        , max_connections
        FROM (
                SELECT COUNT(*) as total
                        , COALESCE(SUM(CASE WHEN state = 'idle' THEN 1 ELSE 0 END),0) AS idle
                        , COALESCE(SUM(CASE WHEN state = 'idle in transaction' THEN 1 ELSE 0 END),0) AS idle_in_txn FROM pg_catalog.pg_stat_activity) x
        JOIN (SELECT setting::float AS max_connections FROM pg_settings WHERE name = 'max_connections') xx ON (true);
INSERT INTO @extschema@.metric_views (
    view_name
    , materialized_view
    , scope )
VALUES (
   'ccp_connection_stats'
    , false
    , 'global');


-- Must be able to get replica stats (cascading replicas), so cannot be matview
CREATE VIEW @extschema@.ccp_replication_lag_size AS
    SELECT client_addr AS replica
        , client_hostname AS replica_hostname
        , client_port AS replica_port
        , pg_wal_lsn_diff(sent_lsn, replay_lsn) AS bytes
        FROM pg_catalog.pg_stat_replication;
INSERT INTO @extschema@.metric_views (
    view_name
    , materialized_view
    , scope )
VALUES (
   'ccp_replication_lag_size'
    , false
    , 'global');


-- Did not make as a matview since this is a critical metric to avoid disk fill
CREATE VIEW @extschema@.ccp_replication_slots AS
    SELECT slot_name, active::int, pg_wal_lsn_diff(CASE WHEN pg_is_in_recovery() THEN pg_last_wal_replay_lsn() ELSE pg_current_wal_insert_lsn() END, restart_lsn) AS retained_bytes FROM pg_catalog.pg_replication_slots;
INSERT INTO @extschema@.metric_views (
    view_name
    , materialized_view
    , scope )
VALUES (
   'ccp_replication_slots'
    , false
    , 'global');


-- Did not make as a matview since this is a critical metric to always be sure is current
CREATE VIEW @extschema@.ccp_data_checksum_failure AS
    SELECT datname AS dbname
    , checksum_failures AS count
    , coalesce(extract(epoch from (clock_timestamp() - checksum_last_failure)), 0) AS time_since_last_failure_seconds
    FROM pg_catalog.pg_stat_database;
INSERT INTO @extschema@.metric_views (
    view_name
    , materialized_view
    , scope )
VALUES (
   'ccp_data_checksum_failure'
    , false
    , 'global');


-- Locks can potentially be different on replicas
CREATE VIEW @extschema@.ccp_locks AS
    SELECT pg_database.datname as dbname
    , tmp.mode
    , COALESCE(count,0) as count
    FROM
    (
      VALUES ('accesssharelock'),
             ('rowsharelock'),
             ('rowexclusivelock'),
             ('shareupdateexclusivelock'),
             ('sharelock'),
             ('sharerowexclusivelock'),
             ('exclusivelock'),
             ('accessexclusivelock')
    ) AS tmp(mode) CROSS JOIN pg_catalog.pg_database
    LEFT JOIN
        (SELECT database, lower(mode) AS mode,count(*) AS count
        FROM pg_catalog.pg_locks WHERE database IS NOT NULL
        GROUP BY database, lower(mode)
    ) AS tmp2
    ON tmp.mode=tmp2.mode and pg_database.oid = tmp2.database;
INSERT INTO @extschema@.metric_views (
    view_name
    , materialized_view
    , scope )
VALUES (
   'ccp_locks'
    , false
    , 'global');


-- WAL activity could be different on replica
CREATE VIEW @extschema@.ccp_wal_activity AS
    SELECT last_5_min_size_bytes,
      (SELECT COALESCE(sum(size),0) FROM pg_catalog.pg_ls_waldir()) AS total_size_bytes
      FROM (SELECT COALESCE(sum(size),0) AS last_5_min_size_bytes FROM pg_catalog.pg_ls_waldir() WHERE modification > CURRENT_TIMESTAMP - '5 minutes'::interval) x;
INSERT INTO @extschema@.metric_views (
    view_name
    , materialized_view
    , scope )
VALUES (
   'ccp_wal_activity'
    , false
    , 'global');


-- Enabling this metric this view will reset the pg_stat_statements statistics based on
--   the run_interval set in metric_views
CREATE VIEW @extschema@.ccp_pg_stat_statements_reset AS
    SELECT @extschema@.pg_stat_statements_reset_info() AS time;
INSERT INTO @extschema@.metric_views (
    view_name
    , materialized_view
    , run_interval
    , scope
    , active )
VALUES (
    'ccp_pg_stat_statements_reset'
    , false
    , '1440 seconds'::interval
    , 'global'
    , false );


-- pgBackRest views
-- All backrest data is pulled from a refreshed table so no need for individual view entries in config table
CREATE VIEW @extschema@.ccp_backrest_last_info AS
    WITH all_backups AS (
      SELECT config_file
       , jsonb_array_elements(data) AS stanza_data
      FROM @extschema@.pgbackrest_info
    )
    , per_stanza AS (
      SELECT config_file
       , stanza_data->>'name' AS stanza
       , jsonb_array_elements(stanza_data->'backup') AS backup_data
      FROM all_backups
    )
    SELECT a.config_file
    , a.stanza
    , split_part(a.backup_data->'backrest'->>'version', '.', 1) || lpad(split_part(a.backup_data->'backrest'->>'version', '.', 2), 2, '0') || lpad(coalesce(nullif(split_part(a.backup_data->'backrest'->>'version', '.', 3), ''), '00'), 2, '0') AS backrest_repo_version
    , a.backup_data->'database'->>'repo-key' AS repo
    , a.backup_data->>'type' AS backup_type
    , a.backup_data->'info'->'repository'->>'delta' AS repo_backup_size_bytes
    , a.backup_data->'info'->'repository'->>'size' AS repo_total_size_bytes
    , (a.backup_data->'timestamp'->>'stop')::bigint - (a.backup_data->'timestamp'->>'start')::bigint AS backup_runtime_seconds
    , CASE
       WHEN a.backup_data->>'error' = 'true' THEN 1
       ELSE 0
     END AS backup_error
    FROM per_stanza a
    JOIN (
          SELECT config_file
              , stanza
              , backup_data->'database'->>'repo-key' AS repo
              , backup_data->>'type' AS backup_type
              , max(backup_data->'timestamp'->>'start') AS max_backup_start
              , max(backup_data->'timestamp'->>'stop') AS max_backup_stop
          FROM per_stanza
          GROUP BY 1,2,3,4) b
    ON a.config_file = b.config_file
    AND a.stanza = b.stanza
    AND a.backup_data->>'type' = b.backup_type
    AND a.backup_data->'timestamp'->>'start' = b.max_backup_start
    AND a.backup_data->'timestamp'->>'stop' = b.max_backup_stop;


CREATE VIEW @extschema@.ccp_backrest_oldest_full_backup AS
    WITH all_backups AS (
      SELECT config_file
       , jsonb_array_elements(data) AS stanza_data
      FROM @extschema@.pgbackrest_info
    )
    , per_stanza AS (
      SELECT config_file
       , stanza_data->>'name' AS stanza
       , jsonb_array_elements(stanza_data->'backup') AS backup_data
      FROM all_backups
    )
    SELECT config_file
    , stanza
    , backup_data->'database'->>'repo-key' AS repo
    , min((backup_data->'timestamp'->>'stop')::bigint) time_seconds
    FROM per_stanza
    WHERE backup_data->>'type' IN ('full')
    GROUP BY config_file, stanza, backup_data->'database'->>'repo-key';


CREATE VIEW @extschema@.ccp_backrest_last_full_backup AS
    WITH all_backups AS (
      SELECT config_file
       , jsonb_array_elements(data) AS stanza_data
      FROM @extschema@.pgbackrest_info
    )
    , per_stanza AS (
      SELECT config_file
       , stanza_data->>'name' AS stanza
       , jsonb_array_elements(stanza_data->'backup') AS backup_data
      FROM all_backups
    )
    SELECT config_file
    , stanza
    , backup_data->'database'->>'repo-key' AS repo
    , extract(epoch from (CURRENT_TIMESTAMP - max(to_timestamp((backup_data->'timestamp'->>'stop')::bigint)))) AS time_since_completion_seconds
    FROM per_stanza
    WHERE backup_data->>'type' IN ('full')
    GROUP BY config_file, stanza, backup_data->'database'->>'repo-key';


CREATE VIEW @extschema@.ccp_backrest_last_diff_backup AS
    WITH all_backups AS (
      SELECT config_file
       , jsonb_array_elements(data) AS stanza_data
    FROM @extschema@.pgbackrest_info
    )
    , per_stanza AS (
      SELECT config_file
       , stanza_data->>'name' AS stanza
       , jsonb_array_elements(stanza_data->'backup') AS backup_data
      FROM all_backups
    )
    SELECT config_file
    , stanza
    , backup_data->'database'->>'repo-key' AS repo
    , extract(epoch from (CURRENT_TIMESTAMP - max(to_timestamp((backup_data->'timestamp'->>'stop')::bigint)))) AS time_since_completion_seconds
    FROM per_stanza
    WHERE backup_data->>'type' IN ('full', 'diff')
    GROUP BY config_file, stanza, backup_data->'database'->>'repo-key';


CREATE VIEW @extschema@.ccp_backrest_last_incr_backup AS
    WITH all_backups AS (
      SELECT config_file
       , jsonb_array_elements(data) AS stanza_data
      FROM @extschema@.pgbackrest_info
    )
    , per_stanza AS (
      SELECT config_file
       , stanza_data->>'name' AS stanza
       , jsonb_array_elements(stanza_data->'backup') AS backup_data
      FROM all_backups
    )
    SELECT config_file
    , stanza
    , backup_data->'database'->>'repo-key' AS repo
    , extract(epoch from (CURRENT_TIMESTAMP - max(to_timestamp((backup_data->'timestamp'->>'stop')::bigint)))) AS time_since_completion_seconds
    FROM per_stanza
    WHERE backup_data->>'type' IN ('full', 'diff', 'incr')
    GROUP BY config_file, stanza, backup_data->'database'->>'repo-key';


CREATE VIEW @extschema@.ccp_stat_bgwriter AS
    SELECT
        buffers_clean
        , maxwritten_clean
        , buffers_alloc
    FROM pg_catalog.pg_stat_bgwriter;
INSERT INTO @extschema@.metric_views (
    view_name
    , materialized_view
    , scope )
VALUES (
   'ccp_stat_bgwriter'
    , false
    , 'global');


CREATE VIEW @extschema@.ccp_stat_checkpointer AS
    SELECT
        num_timed
        , num_requested
        , write_time
        , sync_time
        , buffers_written
    FROM @extschema@.ccp_stat_checkpointer();
INSERT INTO @extschema@.metric_views (
    view_name
    , materialized_view
    , scope )
VALUES (
   'ccp_stat_checkpointer'
    , false
    , 'global');

CREATE VIEW @extschema@.ccp_stat_io_bgwriter AS
    SELECT
        writes
        , fsyncs
    FROM @extschema@.ccp_stat_io_bgwriter();
INSERT INTO @extschema@.metric_views (
    view_name
    , materialized_view
    , scope )
VALUES (
   'ccp_stat_io_bgwriter'
    , false
    , 'global');
