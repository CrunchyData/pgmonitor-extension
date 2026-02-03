-- Locks can potentially be different on replicas
CREATE VIEW @extschema@.pgm_locks AS
    SELECT pg_database.datname as dbname
    , tmp.mode
    , COALESCE(count,0) as count
    FROM
    (
      VALUES ('accesssharelock'),
             ('rowsharelock'),
             ('rowexclusivelock'),
             ('shareupdateexclusivelock'),
             ('sharelock'),
             ('sharerowexclusivelock'),
             ('exclusivelock'),
             ('accessexclusivelock')
    ) AS tmp(mode) CROSS JOIN pg_catalog.pg_database
    LEFT JOIN
        (SELECT database, lower(mode) AS mode,count(*) AS count
        FROM pg_catalog.pg_locks WHERE database IS NOT NULL
        GROUP BY database, lower(mode)
    ) AS tmp2
    ON tmp.mode=tmp2.mode and pg_database.oid = tmp2.database;

INSERT INTO @extschema@.metric_views (
    view_name
    , matview_source
    , scope )
VALUES (
   'pgm_locks'
    , false
    , 'global')
ON CONFLICT DO NOTHING;

