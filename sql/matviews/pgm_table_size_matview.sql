CREATE MATERIALIZED VIEW @extschema@.pgm_table_size_matview AS
    SELECT current_database() as dbname
    , n.nspname as schemaname
    , c.relname
    , pg_catalog.pg_total_relation_size(c.oid) as bytes
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
    WHERE NOT pg_catalog.pg_is_other_temp_schema(n.oid)
    AND relkind IN ('r', 'm', 'f', 'p');
CREATE UNIQUE INDEX pgm_table_size_matview_idx ON @extschema@.pgm_table_size_matview (dbname, schemaname, relname);

INSERT INTO @extschema@.metric_matviews (
    view_name
    , run_interval
    , scope)
VALUES (
    'pgm_table_size_matview'
    , '5 minutes'::interval
    , 'database')
ON CONFLICT DO NOTHING;
