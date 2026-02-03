-- Must be able to get replica stats (cascading replicas), so cannot be matview
CREATE VIEW @extschema@.pgm_replication_lag_size AS
    SELECT client_addr AS replica
        , client_hostname AS replica_hostname
        , client_port AS replica_port
        , pg_wal_lsn_diff(sent_lsn, replay_lsn) AS bytes
        FROM pg_catalog.pg_stat_replication;

INSERT INTO @extschema@.metric_views (
    view_name
    , matview_source
    , scope )
VALUES (
   'pgm_replication_lag_size'
    , false
    , 'global')
ON CONFLICT DO NOTHING;


