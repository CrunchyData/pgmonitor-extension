CREATE VIEW @extschema@.pgm_postmaster_runtime AS
    SELECT extract('epoch' from pg_postmaster_start_time) AS start_time_seconds
    FROM pg_catalog.pg_postmaster_start_time();

INSERT INTO @extschema@.metric_views (
    view_name
    , matview_source
    , scope )
VALUES (
   'pgm_postmaster_runtime'
    , false
    , 'global')
ON CONFLICT DO NOTHING;


