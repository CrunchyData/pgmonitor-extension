-- Must be able to get replica stats, so cannot be matview
CREATE VIEW @extschema@.pgm_replication_lag AS
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
    , matview_source
    , scope )
VALUES (
   'pgm_replication_lag'
    , false
    , 'global')
ON CONFLICT DO NOTHING;


