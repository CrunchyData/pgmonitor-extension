-- Must be able to get replica stats, so cannot be matview
CREATE VIEW @extschema@.pgm_connection_stats AS
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
    , matview_source
    , scope )
VALUES (
   'pgm_connection_stats'
    , false
    , 'global')
ON CONFLICT DO NOTHING;
