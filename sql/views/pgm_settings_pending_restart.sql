CREATE VIEW @extschema@.pgm_settings_pending_restart AS
    SELECT count(*) AS count FROM pg_catalog.pg_settings WHERE pending_restart = true;

INSERT INTO @extschema@.metric_views (
    view_name
    , matview_source
    , scope )
VALUES (
   'pgm_settings_pending_restart'
    , false
    , 'global')
ON CONFLICT DO NOTHING;

