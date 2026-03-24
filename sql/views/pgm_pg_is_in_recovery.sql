CREATE VIEW @extschema@.pgm_pg_is_in_recovery AS
    SELECT CASE WHEN pg_is_in_recovery = true THEN 1 ELSE 2 END AS status from pg_is_in_recovery();

INSERT INTO @extschema@.metric_views (
    view_name
    , matview_source
    , scope )
VALUES (
   'pgm_pg_is_in_recovery'
    , false
    , 'global')
ON CONFLICT DO NOTHING;

