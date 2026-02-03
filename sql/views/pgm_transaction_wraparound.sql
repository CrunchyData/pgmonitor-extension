-- Did not make as a matview since this is a critical metric to always be sure is current
CREATE VIEW @extschema@.pgm_transaction_wraparound AS
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
    , matview_source
    , scope )
VALUES (
   'pgm_transaction_wraparound'
    , false
    , 'global')
ON CONFLICT DO NOTHING;

