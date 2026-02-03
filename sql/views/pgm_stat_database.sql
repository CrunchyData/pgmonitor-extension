CREATE VIEW @extschema@.pgm_stat_database AS
    SELECT s.datname AS dbname
    , s.xact_commit
    , s.xact_rollback
    , s.blks_read
    , s.blks_hit
    , s.tup_returned
    , s.tup_fetched
    , s.tup_inserted
    , s.tup_updated
    , s.tup_deleted
    , s.conflicts
    , s.temp_files
    , s.temp_bytes
    , s.deadlocks
    FROM pg_catalog.pg_stat_database s
    JOIN pg_catalog.pg_database d ON d.datname = s.datname
    WHERE d.datistemplate = false;

INSERT INTO @extschema@.metric_views (
    view_name
    , matview_source
    , scope )
VALUES (
   'pgm_stat_database'
    , false
    , 'global')
ON CONFLICT DO NOTHING;

