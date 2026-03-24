-- Did not make as a matview since this is a critical metric to always be sure is current
CREATE VIEW @extschema@.pgm_data_checksum_failure AS
    SELECT datname AS dbname
    , checksum_failures AS count
    , coalesce(extract(epoch from (clock_timestamp() - checksum_last_failure)), 0) AS time_since_last_failure_seconds
    FROM pg_catalog.pg_stat_database;

INSERT INTO @extschema@.metric_views (
    view_name
    , matview_source
    , scope )
VALUES (
   'pgm_data_checksum_failure'
    , false
    , 'global')
ON CONFLICT DO NOTHING;

