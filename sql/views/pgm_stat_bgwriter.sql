CREATE VIEW @extschema@.pgm_stat_bgwriter AS
    SELECT
        buffers_clean
        , maxwritten_clean
        , buffers_alloc
    FROM pg_catalog.pg_stat_bgwriter;

INSERT INTO @extschema@.metric_views (
    view_name
    , matview_source
    , scope )
VALUES (
   'pgm_stat_bgwriter'
    , false
    , 'global')
ON CONFLICT DO NOTHING;


