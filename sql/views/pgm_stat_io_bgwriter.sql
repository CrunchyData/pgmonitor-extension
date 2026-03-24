CREATE VIEW @extschema@.pgm_stat_io_bgwriter AS
    SELECT
        writes
        , fsyncs
    FROM @extschema@.pgm_stat_io_bgwriter_func();

INSERT INTO @extschema@.metric_views (
    view_name
    , matview_source
    , scope )
VALUES (
   'pgm_stat_io_bgwriter'
    , false
    , 'global')
ON CONFLICT DO NOTHING;


