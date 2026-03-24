-- Did not make as a matview since this is a critical metric to always be sure is current
CREATE VIEW @extschema@.pgm_archive_command_status AS
    SELECT CASE
        WHEN EXTRACT(epoch from (last_failed_time - last_archived_time)) IS NULL THEN 0
        WHEN EXTRACT(epoch from (last_failed_time - last_archived_time)) < 0 THEN 0
        ELSE EXTRACT(epoch from (last_failed_time - last_archived_time))
        END AS seconds_since_last_fail
    , EXTRACT(epoch from (CURRENT_TIMESTAMP - last_archived_time)) AS seconds_since_last_archive
    , archived_count
    , failed_count
    FROM pg_catalog.pg_stat_archiver;

INSERT INTO @extschema@.metric_views (
    view_name
    , matview_source
    , scope )
VALUES (
   'pgm_archive_command_status'
    , false
    , 'global')
ON CONFLICT DO NOTHING;
